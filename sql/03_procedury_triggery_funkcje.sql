/*
====================================================================
PLIK: 03_procedury_triggery_funkcje.sql

ZAKRES: Procedury operacyjne, funkcje i triggery diagnoz.
====================================================================
*/

USE PoradniaDB;
GO


/*
====================================================================
I. PROCEDURY SKŁADOWANE
====================================================================
*/


/*
--------------------------------------------------------------------
PROCEDURA: sp_DodajPlatnosc
--------------------------------------------------------------------

Dla zrealizowanej wizyty bez płatności pobiera cenę z Cennik,
dodaje płatność z datą bieżącą i ustawia status opłacona.
Teleporady opłacane są w sp_ZarejestrujWizyte.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_DodajPlatnosc
    @WizytaID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

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

        IF EXISTS (
            SELECT 1
            FROM Wizyta
            WHERE WizytaID = @WizytaID
              AND StatusWizytyID <> 2
        )
            THROW 50003, 'Platnosc mozna dodac tylko dla wizyty zrealizowanej.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Wizyta w
                JOIN Cennik c
                    ON w.TypWizytyID = c.TypWizytyID
            WHERE w.WizytaID = @WizytaID
        )
            THROW 50004, 'Brak ceny dla wskazanego typu wizyty.', 1;

        INSERT INTO Platnosc (WizytaID, Kwota, DataPlatnosci)
        SELECT
            w.WizytaID,
            c.Kwota,
            GETDATE()
        FROM Wizyta w
            JOIN Cennik c ON w.TypWizytyID = c.TypWizytyID
        WHERE w.WizytaID = @WizytaID;

        IF @@ROWCOUNT <> 1
            THROW 50023, 'Nie udalo sie dodac platnosci do wizyty.', 1;

        UPDATE Wizyta
        SET StatusPlatnosciID = 2
        WHERE WizytaID = @WizytaID;

        IF @@ROWCOUNT <> 1
            THROW 50024, 'Nie udalo sie zaktualizowac statusu platnosci.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_DodajPacjenta
--------------------------------------------------------------------

Dodaje pacjenta po kontroli unikalności PESEL, płci,
pełnoletności i obecności co najmniej jednej formy kontaktu.
Format danych kontaktowych weryfikują ograniczenia tabeli.
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
    THROW 50005, 'Pacjent z podanym numerem PESEL juz istnieje.', 1;

IF @Plec NOT IN ('K','M')
    THROW 50006, 'Niepoprawna wartosc pola Plec.', 1;

IF @DataUrodzenia > DATEADD(YEAR,-18,GETDATE())
    THROW 50007, 'Pacjent musi miec co najmniej 18 lat.', 1;

IF @Telefon IS NULL AND @Email IS NULL
    THROW 50008, 'Nalezy podac przynajmniej telefon lub email.', 1;

INSERT INTO Pacjent
(Imie, Nazwisko, PESEL, DataUrodzenia, Plec, Adres, Telefon, Email)
VALUES
(@Imie, @Nazwisko, @PESEL, @DataUrodzenia, @Plec, @Adres, @Telefon, @Email);

END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_ZarejestrujWizyte
--------------------------------------------------------------------

Sprawdza pacjenta, lekarza, specjalizację, typ i cenę wizyty
oraz termin i brak kolizji w harmonogramie lekarza.
Tworzy wizytę ze statusem umówiona; dla teleporady
dodaje przedpłatę i nadaje status płatności opłacona.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_ZarejestrujWizyte
    @PacjentID INT,
    @LekarzID INT,
    @SpecjalizacjaID INT,
    @DataWizyty DATETIME2(0),
    @TypWizytyID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DataUtworzenia DATETIME2(0) = GETDATE();
    DECLARE @WizytaID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM Pacjent
            WHERE PacjentID = @PacjentID
        )
            THROW 50009, 'Pacjent o podanym ID nie istnieje.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Lekarz
            WHERE LekarzID = @LekarzID
        )
            THROW 50010, 'Lekarz o podanym ID nie istnieje.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM LekarzSpecjalizacja
            WHERE LekarzID = @LekarzID
              AND SpecjalizacjaID = @SpecjalizacjaID
        )
            THROW 50011, 'Lekarz nie posiada wskazanej specjalizacji.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM TypWizyty
            WHERE TypWizytyID = @TypWizytyID
        )
            THROW 50012, 'Typ wizyty o podanym ID nie istnieje.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Cennik
            WHERE TypWizytyID = @TypWizytyID
        )
            THROW 50004, 'Brak ceny dla wskazanego typu wizyty.', 1;

        IF @DataWizyty IS NULL OR @DataWizyty <= @DataUtworzenia
			THROW 50013, 'Nieprawidlowa data wizyty.', 1;

        IF EXISTS (
            SELECT 1
            FROM Wizyta
            WHERE LekarzID = @LekarzID
              AND DataWizyty = @DataWizyty
        )
            THROW 50014, 'Lekarz ma juz zaplanowana wizyte w tym terminie.', 1;

        INSERT INTO Wizyta
        (PacjentID, LekarzID, SpecjalizacjaID, DataWizyty, DataUtworzenia, StatusWizytyID, StatusPlatnosciID, TypWizytyID)
        VALUES
        (@PacjentID,
         @LekarzID,
         @SpecjalizacjaID,
         @DataWizyty,
         @DataUtworzenia,
         1,
         CASE
             WHEN @TypWizytyID = 3 THEN 2
             ELSE 1
         END,
         @TypWizytyID);

        SET @WizytaID = SCOPE_IDENTITY();

        IF @TypWizytyID = 3
        BEGIN
            INSERT INTO Platnosc (
                WizytaID,
                Kwota,
                DataPlatnosci
            )
            SELECT
                @WizytaID,
                Kwota,
                @DataUtworzenia
            FROM Cennik
            WHERE TypWizytyID = @TypWizytyID;

            IF @@ROWCOUNT <> 1
                THROW 50023, 'Nie udalo sie dodac platnosci do wizyty.', 1;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_AnulujWizyte
--------------------------------------------------------------------

Anuluje wyłącznie wizytę umówioną; odrzuca ponowne
anulowanie oraz anulowanie wizyty zrealizowanej.
Dla teleporady zmienia status płatności na zwrot,
zachowując rekord Platnosc; nie realizuje przelewu zwrotnego.
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
    THROW 50015, 'Nie mozna anulowac wizyty zrealizowanej.', 1;

IF EXISTS (
    SELECT 1
    FROM Wizyta
    WHERE WizytaID = @WizytaID
      AND StatusWizytyID = 3
)
    THROW 50016, 'Wizyta jest juz anulowana.', 1;

UPDATE Wizyta
SET
    StatusWizytyID = 3,
    StatusPlatnosciID =
        CASE
            WHEN TypWizytyID = 3 THEN 3
            ELSE 1
        END
WHERE WizytaID = @WizytaID;

END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_ZrealizujWizyte
--------------------------------------------------------------------

Potwierdza realizację wizyty umówionej po nadejściu jej terminu
oraz zapisuje diagnozę ICD-10 w jednej transakcji.
Zgodność diagnozy ze specjalizacją i statusem wizyty kontrolują
triggery tabeli Diagnoza.
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_ZrealizujWizyte
    @WizytaID INT,
    @ICD10ID INT,
    @OpisDodatkowy NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StatusWizytyID INT;
    DECLARE @DataWizyty DATETIME2(0);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @StatusWizytyID = StatusWizytyID,
            @DataWizyty = DataWizyty
        FROM Wizyta WITH (UPDLOCK, HOLDLOCK)
        WHERE WizytaID = @WizytaID;

        IF @StatusWizytyID IS NULL
            THROW 50001, 'Wizyta o podanym ID nie istnieje.', 1;

        IF @StatusWizytyID <> 1
            THROW 50020, 'Zrealizowac mozna tylko wizyte umowiona.', 1;

        IF @DataWizyty > SYSDATETIME()
            THROW 50021, 'Nie mozna zrealizowac wizyty przed jej terminem.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM ICD10
            WHERE ICD10ID = @ICD10ID
        )
            THROW 50025, 'Wskazany kod ICD10 nie istnieje.', 1;

        UPDATE Wizyta
        SET StatusWizytyID = 2
        WHERE WizytaID = @WizytaID
          AND StatusWizytyID = 1
          AND DataWizyty <= SYSDATETIME();

        IF @@ROWCOUNT <> 1
            THROW 50022, 'Nie udalo sie zmienic statusu wizyty.', 1;

        INSERT INTO Diagnoza (WizytaID, ICD10ID, OpisDodatkowy)
        VALUES (@WizytaID, @ICD10ID, @OpisDodatkowy);

        IF @@ROWCOUNT <> 1
            THROW 50026, 'Nie udalo sie dodac diagnozy do wizyty.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_SprawdzDostepnoscLekarza
--------------------------------------------------------------------

Sprawdza istnienie lekarza oraz dostępność przyszłego terminu.
Brak daty zgłasza jako błąd 50013. Pozostałe wyniki zwraca
zgodnie z zasadami tabeli Wizyta: dni robocze (pon.–pt.),
godziny rozpoczęcia 08:00–15:30 i interwał 30 minut.
Zajętość uwzględnia wszystkie wizyty, także anulowane,
zgodnie z ograniczeniem UNIQUE(LekarzID, DataWizyty).
Nie uwzględnia indywidualnych grafików lekarzy..
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_SprawdzDostepnoscLekarza
    @LekarzID INT,
    @DataWizyty DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Lekarz
        WHERE LekarzID = @LekarzID
    )
        THROW 50010, 'Lekarz o podanym ID nie istnieje.', 1;

    IF @DataWizyty IS NULL
        THROW 50013, 'Nieprawidlowa data wizyty.', 1;

    SELECT
        CASE
            WHEN @DataWizyty <= SYSDATETIME()
                THEN N'Termin w przeszłości'

            -- Niezależnie od ustawienia DATEFIRST: 1900-01-01 był poniedziałkiem.
            WHEN DATEDIFF(DAY, '19000101', CAST(@DataWizyty AS DATE)) % 7
                 NOT BETWEEN 0 AND 4
                THEN N'Termin poza dniami pracy'

            WHEN DATEPART(HOUR, @DataWizyty) NOT BETWEEN 8 AND 15
                THEN N'Termin poza godzinami pracy'

            WHEN DATEPART(MINUTE, @DataWizyty) NOT IN (0, 30)
                 OR DATEPART(SECOND, @DataWizyty) <> 0
                THEN N'Nieprawidłowy interwał terminu'

            WHEN EXISTS (
                SELECT 1
                FROM Wizyta
                WHERE LekarzID = @LekarzID
                  AND DataWizyty = @DataWizyty
            )
                THEN N'Termin zajęty'

            ELSE N'Termin dostępny'
        END AS Status;
END;
GO




/*
--------------------------------------------------------------------
PROCEDURA: sp_HistoriaPacjenta
--------------------------------------------------------------------

Zwraca dane z vw_HistoriaWizytPacjenta dla wskazanego
pacjenta, malejąco według DataWizyty.
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
    THROW 50009, 'Pacjent o podanym ID nie istnieje.', 1;

SELECT *
FROM vw_HistoriaWizytPacjenta
WHERE PacjentID = @PacjentID
ORDER BY DataWizyty DESC;

END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_RaportMiesieczny
--------------------------------------------------------------------

Wizyty zrealizowane liczy według daty wizyty;
przychód z tych wizyt sumuje według daty płatności.
Parametry: rok i miesiąc (1–12).
--------------------------------------------------------------------
*/

CREATE PROCEDURE sp_RaportMiesieczny
    @Rok INT,
    @Miesiac INT
AS
BEGIN

IF @Miesiac NOT BETWEEN 1 AND 12
    THROW 50017, 'Miesiac musi miec wartosc od 1 do 12.', 1;

DECLARE @DataOd DATE = DATEFROMPARTS(@Rok, @Miesiac, 1);
DECLARE @DataDo DATE = DATEADD(MONTH, 1, @DataOd);

SELECT
    (SELECT COUNT(*)
     FROM Wizyta w
     WHERE w.StatusWizytyID = 2
          AND w.DataWizyty >= @DataOd
          AND w.DataWizyty < @DataDo
    ) AS LiczbaWizyt,

    (SELECT COALESCE(SUM(p.Kwota), 0)
     FROM Platnosc p
            JOIN Wizyta w ON p.WizytaID = w.WizytaID
     WHERE w.StatusWizytyID = 2
          AND p.DataPlatnosci >= @DataOd
          AND p.DataPlatnosci < @DataDo
    ) AS Przychod;

END;
GO



/*
--------------------------------------------------------------------
PROCEDURA: sp_StatystykaLekarza
--------------------------------------------------------------------

Liczba zrealizowanych wizyt lekarza i suma przypisanych
do nich kwot, bez ograniczenia dat wizyt lub płatności.
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
    THROW 50010, 'Lekarz o podanym ID nie istnieje.', 1;

SELECT
    COUNT(*) AS LiczbaWizyt,
    COALESCE(SUM(p.Kwota), 0) AS Przychod
FROM Wizyta w
LEFT JOIN Platnosc p ON w.WizytaID = p.WizytaID
WHERE 
    w.LekarzID = @LekarzID
    AND w.StatusWizytyID = 2;

END;
GO



/*
====================================================================
II. FUNKCJE UŻYTKOWNIKA
====================================================================
*/


/*
--------------------------------------------------------------------
FUNKCJA: fn_WiekPacjenta
--------------------------------------------------------------------

Wiek w pełnych latach na dzień wykonania funkcji (GETDATE);
odrębny od wieku liczonego na stałą datę w Power BI.
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
GO



/*
FUNKCJA: fn_LiczbaWizytPacjenta
--------------------------------------------------------------------

Liczba wszystkich wizyt wskazanego pacjenta, niezależnie
od statusu i daty wizyty.
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
GO



/*
====================================================================
III. TRIGGERY
====================================================================

Oba triggery uruchamiane są po INSERT; nie obsługują UPDATE.
====================================================================
*/


/*
--------------------------------------------------------------------
TRIGGER: trg_Diagnoza_Specjalizacja
--------------------------------------------------------------------

AFTER INSERT: odrzuca rozpoznanie ICD-10 nieprzypisane
do specjalizacji wskazanej w wizycie.
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
        LEFT JOIN SpecjalizacjaICD10 si
            ON si.SpecjalizacjaID = w.SpecjalizacjaID
           AND si.ICD10ID = i.ICD10ID
        WHERE si.ICD10ID IS NULL
    )
        THROW 50018, 'Kod ICD10 jest niezgodny ze specjalizacja przypisana do wizyty.', 1;

END;
GO



/*
--------------------------------------------------------------------
TRIGGER: trg_Diagnoza_Status
--------------------------------------------------------------------

AFTER INSERT: odrzuca diagnozę dla wizyty o statusie
innym niż zrealizowana.
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
        THROW 50019, 'Diagnoza moze byc dodana tylko dla wizyty zrealizowanej.', 1;

END;
GO
