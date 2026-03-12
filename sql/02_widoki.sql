/*
====================================================================
PLIK: 02_widoki.sql

Skrypt definiuje widoki wykorzystywane do:
- kontroli integralności i spójności danych
- analizy operacyjnej systemu poradni
- raportowania medycznego i finansowego
- zasilania warstwy analitycznej
====================================================================
*/



/*
====================================================================
I. WIDOKI KONTROLNE
====================================================================

Widoki służą do identyfikacji potencjalnych niespójności
w danych operacyjnych systemu. Pozwalają wykryć błędy
wprowadzania danych lub nieprawidłowy przebieg procesów
biznesowych (diagnostycznych i finansowych).
====================================================================
*/


/*
--------------------------------------------------------------------
WIDOK: vw_WizytaBezDiagnozy

Identyfikuje wizyty oznaczone jako zrealizowane,
dla których nie zarejestrowano rozpoznania medycznego
w tabeli Diagnoza.
--------------------------------------------------------------------
*/

CREATE VIEW vw_WizytaBezDiagnozy AS
SELECT *
FROM Wizyta w
WHERE w.StatusWizytyID = 2
AND NOT EXISTS (
    SELECT 1 FROM Diagnoza d WHERE d.WizytaID = w.WizytaID
);



/*
--------------------------------------------------------------------
WIDOK: vw_WizytaBezPlatnosci

Wykrywa wizyty oznaczone jako opłacone,
dla których brak odpowiadającego rekordu
w tabeli Platnosc.
--------------------------------------------------------------------
*/

CREATE VIEW vw_WizytaBezPlatnosci AS
SELECT *
FROM Wizyta w
WHERE w.StatusPlatnosciID = 2
AND NOT EXISTS (
    SELECT 1 FROM Platnosc p WHERE p.WizytaID = w.WizytaID
);



/*
--------------------------------------------------------------------
WIDOK: vw_WiecejNiz1Wizyta

Identyfikuje pacjentów posiadających więcej niż jedną
wizytę w tym samym miesiącu kalendarzowym.

Widok pomocniczy wykorzystywany głównie
podczas weryfikacji danych testowych.
--------------------------------------------------------------------
*/

CREATE VIEW vw_WiecejNiz1Wizyta AS
SELECT 
    PacjentID,
    YEAR(DataWizyty) AS Rok,
    MONTH(DataWizyty) AS Miesiac,
    COUNT(*) AS LiczbaWizyt
FROM Wizyta
GROUP BY PacjentID, YEAR(DataWizyty), MONTH(DataWizyty)
HAVING COUNT(*) > 1;



/*
--------------------------------------------------------------------
WIDOK: vw_NiespojnoscStatusow

Wykrywa niespójności logiczne pomiędzy statusem wizyty
a statusem płatności.

Kontrolowane przypadki obejmują m.in.:
- wizytę zrealizowaną bez zarejestrowanej płatności
- anulowaną wizytę stacjonarną z płatnością
- anulowaną teleporadę bez zwrotu środków
--------------------------------------------------------------------
*/

CREATE VIEW vw_NiespojnoscStatusow AS
SELECT *
FROM Wizyta
WHERE
    (StatusWizytyID = 2 AND StatusPlatnosciID <> 2)
    OR
    (StatusWizytyID = 3 AND TypWizytyID <> 3 AND StatusPlatnosciID <> 1)
    OR
    (StatusWizytyID = 3 AND TypWizytyID = 3 AND StatusPlatnosciID <> 3);



/*
--------------------------------------------------------------------
WIDOK: vw_PlatnoscNiezgodnaZCennikiem

Identyfikuje płatności, których kwota nie odpowiada
wartości zdefiniowanej w tabeli Cennik dla danego typu wizyty.
--------------------------------------------------------------------
*/

CREATE VIEW vw_PlatnoscNiezgodnaZCennikiem AS
SELECT 
    p.PlatnoscID,
    p.WizytaID,
    p.Kwota AS Kwota_Platnosci,
    c.Kwota AS Kwota_Z_Cennika,
    w.TypWizytyID
FROM Platnosc p
    JOIN Wizyta w ON p.WizytaID = w.WizytaID
    JOIN Cennik c ON w.TypWizytyID = c.TypWizytyID
WHERE p.Kwota <> c.Kwota;



/*
====================================================================
II. WIDOKI ANALITYCZNE
====================================================================

Widoki wspierające analizę danych operacyjnych poradni.
Umożliwiają raportowanie kliniczne, analizę aktywności
lekarzy oraz monitorowanie przychodów.
====================================================================
*/


/*
--------------------------------------------------------------------
WIDOK: vw_HistoriaKliniczna

Agreguje historię rozpoznań medycznych pacjentów
na podstawie diagnoz przypisanych do wizyt.
--------------------------------------------------------------------
*/

CREATE VIEW vw_HistoriaKliniczna AS
SELECT 
    p.PacjentID,
    p.Imie,
    p.Nazwisko,
    i.Kod,
    i.Nazwa,
    COUNT(*) AS LiczbaRozpoznan,
    MIN(w.DataWizyty) AS PierwszaWizyta,
    MAX(w.DataWizyty) AS OstatniaWizyta
FROM Diagnoza d
    JOIN Wizyta w ON d.WizytaID = w.WizytaID
    JOIN Pacjent p ON w.PacjentID = p.PacjentID
    JOIN ICD10 i ON d.ICD10ID = i.ICD10ID
GROUP BY p.PacjentID, p.Imie, p.Nazwisko, i.Kod, i.Nazwa;



/*
--------------------------------------------------------------------
WIDOK: vw_HistoriaWizytPacjenta

Szczegółowa historia wizyt pacjenta zawierająca
informacje o lekarzu, specjalizacji, typie wizyty,
statusie wizyty, diagnozie oraz płatności.
--------------------------------------------------------------------
*/

CREATE VIEW vw_HistoriaWizytPacjenta AS
SELECT
    p.PacjentID,
    p.Imie AS PacjentImie,
    p.Nazwisko AS PacjentNazwisko,
    w.WizytaID,
    w.DataWizyty,
    u.Imie AS LekarzImie,
    u.Nazwisko AS LekarzNazwisko,
    s.Nazwa AS Specjalizacja,
    tw.Nazwa AS TypWizyty,
    sw.Nazwa AS StatusWizyty,
    i.Kod AS KodICD10,
    i.Nazwa AS Diagnoza,
    pl.Kwota
FROM Wizyta w
    JOIN Pacjent p ON w.PacjentID = p.PacjentID
    JOIN Lekarz l ON w.LekarzID = l.LekarzID
    JOIN Uzytkownik u ON l.UzytkownikID = u.UzytkownikID
    LEFT JOIN LekarzSpecjalizacja ls ON l.LekarzID = ls.LekarzID
    LEFT JOIN Specjalizacja s ON ls.SpecjalizacjaID = s.SpecjalizacjaID
    JOIN TypWizyty tw ON w.TypWizytyID = tw.TypWizytyID
    JOIN StatusWizyty sw ON w.StatusWizytyID = sw.StatusWizytyID
    LEFT JOIN Diagnoza d ON w.WizytaID = d.WizytaID
    LEFT JOIN ICD10 i ON d.ICD10ID = i.ICD10ID
    LEFT JOIN Platnosc pl ON w.WizytaID = pl.WizytaID;



/*
--------------------------------------------------------------------
WIDOK: vw_GrafikLekarza

Harmonogram wizyt lekarzy zawierający
podstawowe informacje o pacjentach
oraz typie i statusie wizyty.
--------------------------------------------------------------------
*/

CREATE VIEW vw_GrafikLekarza AS
SELECT
    l.LekarzID,
    u.Imie AS LekarzImie,
    u.Nazwisko AS LekarzNazwisko,
    s.Nazwa AS Specjalizacja,
    w.WizytaID,
    w.DataWizyty,
    p.Imie AS PacjentImie,
    p.Nazwisko AS PacjentNazwisko,
    tw.Nazwa AS TypWizyty,
    sw.Nazwa AS StatusWizyty
FROM Wizyta w
    JOIN Lekarz l ON w.LekarzID = l.LekarzID
    JOIN Uzytkownik u ON l.UzytkownikID = u.UzytkownikID
    LEFT JOIN LekarzSpecjalizacja ls ON l.LekarzID = ls.LekarzID
    LEFT JOIN Specjalizacja s ON ls.SpecjalizacjaID = s.SpecjalizacjaID
    JOIN Pacjent p ON w.PacjentID = p.PacjentID
    JOIN TypWizyty tw ON w.TypWizytyID = tw.TypWizytyID
    JOIN StatusWizyty sw ON w.StatusWizytyID = sw.StatusWizytyID;



/*
--------------------------------------------------------------------
WIDOK: vw_OblozenieLekarzy

Agreguje liczbę zrealizowanych wizyt
oraz wygenerowany przychód dla każdego lekarza.
--------------------------------------------------------------------
*/

CREATE VIEW vw_OblozenieLekarzy AS
SELECT
    l.LekarzID,
    u.Imie,
    u.Nazwisko,
    COUNT(w.WizytaID) AS LiczbaWizyt,
    SUM(p.Kwota) AS Przychod
FROM Lekarz l
    JOIN Uzytkownik u ON l.UzytkownikID = u.UzytkownikID
    LEFT JOIN Wizyta w ON l.LekarzID = w.LekarzID
    AND w.StatusWizytyID = 2
    LEFT JOIN Platnosc p ON w.WizytaID = p.WizytaID
GROUP BY l.LekarzID, u.Imie, u.Nazwisko;



/*
--------------------------------------------------------------------
WIDOK: vw_RaportPrzychodow

Agregacja przychodów poradni
w podziale na miesiące kalendarzowe.
--------------------------------------------------------------------
*/

CREATE VIEW vw_RaportPrzychodow AS
SELECT
    YEAR(w.DataWizyty) AS Rok,
    MONTH(w.DataWizyty) AS Miesiac,
    SUM(p.Kwota) AS Przychod
FROM Platnosc p
    JOIN Wizyta w ON p.WizytaID = w.WizytaID
WHERE w.StatusWizytyID = 2
GROUP BY
    YEAR(w.DataWizyty),
    MONTH(w.DataWizyty);



/*
--------------------------------------------------------------------
WIDOK: vw_PrzychodyLekarzy

Miesięczna agregacja przychodów generowanych
przez poszczególnych lekarzy.
--------------------------------------------------------------------
*/

CREATE VIEW vw_PrzychodyLekarzy AS
SELECT
    YEAR(w.DataWizyty) AS Rok,
    MONTH(w.DataWizyty) AS Miesiac,
    l.LekarzID,
    u.Imie,
    u.Nazwisko,
    SUM(p.Kwota) AS Przychod
FROM Platnosc p
    JOIN Wizyta w ON p.WizytaID = w.WizytaID
    JOIN Lekarz l ON w.LekarzID = l.LekarzID
    JOIN Uzytkownik u ON l.UzytkownikID = u.UzytkownikID
WHERE w.StatusWizytyID = 2
GROUP BY
    YEAR(w.DataWizyty),
    MONTH(w.DataWizyty),
    l.LekarzID,
    u.Imie,
    u.Nazwisko;



/*
--------------------------------------------------------------------
WIDOK: vw_NajczestszeDiagnozy

Ranking najczęściej rejestrowanych
rozpoznań medycznych (ICD-10).
--------------------------------------------------------------------
*/

CREATE VIEW vw_NajczestszeDiagnozy AS
SELECT
    i.Kod,
    i.Nazwa,
    COUNT(*) AS LiczbaWystapien
FROM Diagnoza d
    JOIN ICD10 i ON d.ICD10ID = i.ICD10ID
GROUP BY
    i.Kod,
    i.Nazwa;



/*
--------------------------------------------------------------------
WIDOK: vw_FactWizyty

Zdenormalizowany widok analityczny integrujący
kluczowe dane operacyjne systemu.

Pełni rolę tabeli faktów w modelu raportowym
wykorzystywanym w narzędziach BI.
--------------------------------------------------------------------
*/

CREATE VIEW vw_FactWizyty AS
SELECT
    w.WizytaID,
    w.DataWizyty,
    YEAR(w.DataWizyty) AS Rok,
    MONTH(w.DataWizyty) AS Miesiac,
    DAY(w.DataWizyty) AS Dzien,
    p.PacjentID,
    p.Imie AS PacjentImie,
    p.Nazwisko AS PacjentNazwisko,
    p.Plec,
    l.LekarzID,
    u.Imie AS LekarzImie,
    u.Nazwisko AS LekarzNazwisko,
    tw.Nazwa AS TypWizyty,
    sw.Nazwa AS StatusWizyty,
    icd.Kod AS KodICD10,
    icd.Nazwa AS NazwaICD10,
    pl.Kwota
FROM Wizyta w
    JOIN Pacjent p ON w.PacjentID = p.PacjentID
    JOIN Lekarz l ON w.LekarzID = l.LekarzID
    JOIN Uzytkownik u ON l.UzytkownikID = u.UzytkownikID
    JOIN TypWizyty tw ON w.TypWizytyID = tw.TypWizytyID
    JOIN StatusWizyty sw ON w.StatusWizytyID = sw.StatusWizytyID
    LEFT JOIN Diagnoza d ON w.WizytaID = d.WizytaID
    LEFT JOIN ICD10 icd ON d.ICD10ID = icd.ICD10ID
    LEFT JOIN Platnosc pl ON w.WizytaID = pl.WizytaID
WHERE w.StatusWizytyID = 2;