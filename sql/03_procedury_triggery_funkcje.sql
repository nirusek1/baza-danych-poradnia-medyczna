/*
====================================================================
PLIK: 03_procedury_triggery_funkcje.sql

Skrypt definiuje elementy logiki aplikacyjnej bazy danych:
- procedury składowane obsługujące operacje biznesowe
- funkcje użytkownika wykorzystywane w zapytaniach
- triggery egzekwujące reguły integralności

Obiekty te odpowiadają za walidację danych,
automatyzację procesów oraz utrzymanie spójności
modelu danych poradni medycznej.
====================================================================
*/



/*
====================================================================
I. PROCEDURY SKŁADOWANE
====================================================================

Procedury implementują operacje biznesowe systemu
związane z obsługą wizyt, diagnoz oraz płatności.

Zastosowanie procedur pozwala:
- centralizować logikę aplikacyjną
- ograniczyć bezpośredni dostęp do tabel
- zapewnić spójność operacji zapisu danych
====================================================================
*/


/*
--------------------------------------------------------------------
PROCEDURA: sp_DodajPlatnosc

Tworzy rekord płatności dla wskazanej wizyty.

Kwota pobierana jest z tabeli Cennik na podstawie typu wizyty.
Data płatności ustalana jest zgodnie z typem wizyty
(teleporada – DataUtworzenia, wizyta stacjonarna – DataWizyty).

Po utworzeniu płatności aktualizowany jest StatusPlatnosciID wizyty.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_DodajPlatnosc
    @WizytaID INT
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE WizytaID = @WizytaID
)
    THROW 50001, 'Wizyta o podanym ID nie istnieje.', 1;

IF EXISTS (
    SELECT 1
    FROM Platnosc
    WHERE WizytaID = @WizytaID
)
    THROW 50002, 'Platnosc dla tej wizyty juz istnieje.', 1;

INSERT INTO Platnosc (WizytaID, Kwota, DataPlatnosci)
SELECT 
    w.WizytaID,
    c.Kwota,
    CASE 
        WHEN w.TypWizytyID = 3 THEN w.DataUtworzenia
        ELSE w.DataWizyty
    END
FROM Wizyta w
    JOIN Cennik c ON w.TypWizytyID = c.TypWizytyID
WHERE w.WizytaID = @WizytaID AND w.StatusWizytyID = 2;

UPDATE Wizyta
SET StatusPlatnosciID = 2
WHERE WizytaID = @WizytaID AND StatusWizytyID = 2;

END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_DodajPacjenta

Rejestruje pacjenta w tabeli Pacjent.

Walidacja:
- unikalność PESEL
- poprawność wartości Plec
- minimalny wiek pacjenta
- wymagana co najmniej jedna forma kontaktu
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_DodajPacjenta
    @Imie NVARCHAR(50),
    @Nazwisko NVARCHAR(80),
    @PESEL CHAR(11),
    @DataUrodzenia DATE,
    @Plec CHAR(1),
    @Adres NVARCHAR(200),
    @Telefon NVARCHAR(20) = NULL,
    @Email NVARCHAR(100) = NULL
AS
BEGIN

IF EXISTS (
    SELECT 1
    FROM Pacjent
    WHERE PESEL = @PESEL
)
    THROW 50003, 'Pacjent z podanym numerem PESEL juz istnieje.', 1;

IF @Plec NOT IN ('K','M')
    THROW 50004, 'Niepoprawna wartosc pola Plec.', 1;

IF @DataUrodzenia > DATEADD(YEAR,-18,GETDATE())
    THROW 50005, 'Pacjent musi miec co najmniej 18 lat.', 1;

IF @Telefon IS NULL AND @Email IS NULL
    THROW 50006, 'Nalezy podac przynajmniej telefon lub email.', 1;

INSERT INTO Pacjent
(Imie, Nazwisko, PESEL, DataUrodzenia, Plec, Adres, Telefon, Email)
VALUES
(@Imie, @Nazwisko, @PESEL, @DataUrodzenia, @Plec, @Adres, @Telefon, @Email);

END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_ZarejestrujWizyte

Tworzy rekord wizyty powiązanej z pacjentem i lekarzem.

Walidacja:
- istnienie pacjenta i lekarza
- poprawność daty wizyty
- brak konfliktu terminu dla lekarza

StatusWizytyID inicjalizowany jako „umówiona”.
StatusPlatnosciID zależny od typu wizyty.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_ZarejestrujWizyte
    @PacjentID INT,
    @LekarzID INT,
    @DataWizyty DATETIME2,
    @TypWizytyID INT
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Pacjent
    WHERE PacjentID = @PacjentID
)
    THROW 50007, 'Pacjent o podanym ID nie istnieje.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM Lekarz
    WHERE LekarzID = @LekarzID
)
    THROW 50008, 'Lekarz o podanym ID nie istnieje.', 1;

IF @DataWizyty < GETDATE()
    THROW 50009, 'Nieprawidłowa data wizyty.', 1;

IF EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE LekarzID = @LekarzID
      AND DataWizyty = @DataWizyty
)
    THROW 50010, 'Lekarz ma juz zaplanowana wizyte w tym terminie.', 1;

INSERT INTO Wizyta
(PacjentID, LekarzID, DataWizyty, DataUtworzenia, StatusWizytyID, StatusPlatnosciID, TypWizytyID)
VALUES
(@PacjentID, 
@LekarzID, 
@DataWizyty, 
GETDATE(), 
1, 
CASE 
    WHEN @TypWizytyID = 3 THEN 2
    ELSE 1
END, 
@TypWizytyID);

END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_AnulujWizyte

Zmienia status wizyty na „anulowana”.

Operacja blokowana dla wizyt zrealizowanych
oraz wcześniej anulowanych.

Dla teleporady ustawiany jest status płatności „zwrot”.
Rekord w tabeli Platnosc pozostaje jako zapis historii finansowej.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_AnulujWizyte
    @WizytaID INT
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE WizytaID = @WizytaID
)
    THROW 50001, 'Wizyta o podanym ID nie istnieje.', 1;

IF EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE WizytaID = @WizytaID
      AND StatusWizytyID = 2
)
    THROW 50011, 'Nie mozna anulowac wizyty zrealizowanej.', 1;

IF EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE WizytaID = @WizytaID
      AND StatusWizytyID = 3
)
    THROW 50012, 'Wizyta jest juz anulowana.', 1;

UPDATE Wizyta
SET
    StatusWizytyID = 3,
    StatusPlatnosciID =
        CASE
            WHEN TypWizytyID = 3 THEN 3
            ELSE 1
        END
WHERE WizytaID = @WizytaID;

END



/*
--------------------------------------------------------------------
PROCEDURA: sp_SprawdzDostepnoscLekarza

Weryfikuje dostępność lekarza w określonym terminie.

Sprawdza istnienie wizyty dla wskazanego lekarza
i daty w tabeli Wizyta.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_SprawdzDostepnoscLekarza
    @LekarzID INT,
    @DataWizyty DATETIME2
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Lekarz
    WHERE LekarzID = @LekarzID
)
    THROW 50008, 'Lekarz o podanym ID nie istnieje.', 1;

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM Wizyta
            WHERE LekarzID = @LekarzID AND DataWizyty = @DataWizyty
        )
        THEN 'Termin zajęty'
        ELSE 'Termin dostępny'
    END AS Status;
END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_HistoriaPacjenta

Zwraca historię wizyt pacjenta na podstawie widoku
vw_HistoriaWizytPacjenta.

Wyniki sortowane malejąco według DataWizyty.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_HistoriaPacjenta
    @PacjentID INT
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Pacjent
    WHERE PacjentID = @PacjentID
)
    THROW 50007, 'Pacjent o podanym ID nie istnieje.', 1;

SELECT *
FROM vw_HistoriaWizytPacjenta
WHERE PacjentID = @PacjentID
ORDER BY DataWizyty DESC;

END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_RaportMiesieczny

Agreguje dane operacyjne dla wskazanego miesiąca:

- liczba wizyt zrealizowanych
- łączny przychód z płatności
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_RaportMiesieczny
    @Rok INT,
    @Miesiac INT
AS
BEGIN

SELECT
    COUNT(*) AS LiczbaWizyt,
    SUM(p.Kwota) AS Przychod
FROM Wizyta w
LEFT JOIN Platnosc p ON w.WizytaID = p.WizytaID
WHERE
    YEAR(w.DataWizyty) = @Rok
    AND MONTH(w.DataWizyty) = @Miesiac
    AND w.StatusWizytyID = 2;

END;



/*
--------------------------------------------------------------------
PROCEDURA: sp_StatystykaLekarza

Zwraca statystyki pracy lekarza:

- liczba wizyt zrealizowanych
- wygenerowany przychód
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_StatystykaLekarza
    @LekarzID INT
AS
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM Lekarz
    WHERE LekarzID = @LekarzID
)
    THROW 50008, 'Lekarz o podanym ID nie istnieje.', 1;

SELECT
    COUNT(*) AS LiczbaWizyt,
    SUM(p.Kwota) AS Przychod
FROM Wizyta w
LEFT JOIN Platnosc p ON w.WizytaID = p.WizytaID
WHERE 
    w.LekarzID = @LekarzID
    AND w.StatusWizytyID = 2;

END;



/*
====================================================================
II. FUNKCJE UŻYTKOWNIKA
====================================================================

Funkcje udostępniają logikę pomocniczą wykorzystywaną
w zapytaniach analitycznych oraz procedurach biznesowych.
====================================================================
*/


/*
--------------------------------------------------------------------
FUNKCJA: fn_WiekPacjenta

Oblicza wiek pacjenta w latach na podstawie daty urodzenia.
Funkcja wykorzystywana w analizach demograficznych
oraz raportach statystycznych.
--------------------------------------------------------------------
*/

CREATE FUNCTION fn_WiekPacjenta (@DataUrodzenia DATE)
RETURNS INT
AS
BEGIN
RETURN DATEDIFF(YEAR, @DataUrodzenia, GETDATE())
       - CASE 
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DataUrodzenia, GETDATE()), @DataUrodzenia) > GETDATE()
            THEN 1 ELSE 0
         END
END;



/*
--------------------------------------------------------------------
FUNKCJA: fn_LiczbaWizytPacjenta

Zwraca liczbę wizyt przypisanych do wskazanego pacjenta.

Funkcja pomocnicza wykorzystywana w analizach
aktywności pacjentów oraz w procedurach raportowych.
--------------------------------------------------------------------
*/

CREATE FUNCTION fn_LiczbaWizytPacjenta (@PacjentID INT)
RETURNS INT
AS
BEGIN

DECLARE @Liczba INT;

SELECT @Liczba = COUNT(*)
FROM Wizyta
WHERE PacjentID = @PacjentID;

RETURN @Liczba;

END;



/*
====================================================================
III. TRIGGERY
====================================================================

Triggery odpowiadają za automatyczne egzekwowanie
wybranych reguł integralności danych oraz
obsługę zdarzeń zachodzących podczas operacji
INSERT / UPDATE / DELETE.
====================================================================
*/


/*
--------------------------------------------------------------------
TRIGGER: trg_Diagnoza_Specjalizacja

Weryfikuje zgodność kodu ICD10 z zakresem diagnoz
dopuszczonych dla specjalizacji lekarza realizującego wizytę.

Naruszenie reguły przerywa operację INSERT.
--------------------------------------------------------------------
*/

CREATE TRIGGER trg_Diagnoza_Specjalizacja
ON Diagnoza
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Wizyta w 
            ON i.WizytaID = w.WizytaID
        LEFT JOIN LekarzSpecjalizacja ls
            ON w.LekarzID = ls.LekarzID
        LEFT JOIN SpecjalizacjaICD10 s
            ON s.SpecjalizacjaID = ls.SpecjalizacjaID
           AND s.ICD10ID = i.ICD10ID
        WHERE s.ICD10ID IS NULL
    )
        THROW 50013, 'Kod ICD10 jest niezgodny ze specjalizacja lekarza.', 1;
END;



/*
--------------------------------------------------------------------
TRIGGER: trg_Diagnoza_Status

Wymusza dodawanie diagnozy wyłącznie do wizyt
o statusie „zrealizowana”.
--------------------------------------------------------------------
*/

CREATE TRIGGER trg_Diagnoza_Status
ON Diagnoza
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Wizyta w ON i.WizytaID = w.WizytaID
        WHERE w.StatusWizytyID <> 2
    )
        THROW 50014, 'Diagnoza moze byc dodana tylko dla wizyty zrealizowanej.', 1;
END;
