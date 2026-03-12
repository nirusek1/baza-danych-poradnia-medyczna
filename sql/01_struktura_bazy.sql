/*
====================================================================
PROJEKT: Baza danych prywatnej poradni specjalistycznej
BAZA DANYCH: PoradniaDB
PLIK: 01_struktura_bazy.sql

Skrypt definiuje strukturę relacyjnej bazy danych systemu poradni.
Zawiera definicje tabel, kluczy głównych, kluczy obcych oraz
ograniczeń integralności danych.
====================================================================
*/

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF DB_ID('PoradniaDB') IS NULL
BEGIN
    CREATE DATABASE PoradniaDB;
END
GO

USE PoradniaDB;
GO



/*
====================================================================
I. TABELE SŁOWNIKOWE
====================================================================

Zbiory wartości referencyjnych wykorzystywane w relacjach oraz
walidacji danych (np. typ wizyty, status wizyty, status płatności,
rola użytkownika, specjalizacja lekarska, kody klasyfikacji ICD-10).
====================================================================
*/

CREATE TABLE Rola (
    RolaID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE StatusWizyty (
    StatusWizytyID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE StatusPlatnosci (
    StatusPlatnosciID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE TypWizyty (
    TypWizytyID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Specjalizacja (
    SpecjalizacjaID INT IDENTITY(1,1) PRIMARY KEY,
    Nazwa NVARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE ICD10 (
    ICD10ID INT IDENTITY(1,1) PRIMARY KEY,
    Kod VARCHAR(10) NOT NULL UNIQUE,
    Nazwa NVARCHAR(255) NOT NULL
);
GO



/*
====================================================================
II. TABELA POMOCNICZA
====================================================================

Tabela przechowująca cennik wizyt medycznych przypisany do typu
wizyty. Dane wykorzystywane przy generowaniu informacji o płatności.
====================================================================
*/

CREATE TABLE Cennik (
    TypWizytyID INT PRIMARY KEY,
    Kwota DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Cennik_TypWizyty 
        FOREIGN KEY (TypWizytyID)    
        REFERENCES TypWizyty(TypWizytyID),

    CONSTRAINT CK_Cennik_Kwota
        CHECK (Kwota > 0)
);
GO



/*
====================================================================
III. TABELE GŁÓWNE
====================================================================

Encje operacyjne systemu: pacjenci, użytkownicy systemu,
lekarze, wizyty, diagnozy oraz płatności.
====================================================================
*/


/*
--------------------------------------------------------------------
TABELA: Pacjent
--------------------------------------------------------------------

Dane identyfikacyjne pacjentów poradni.

Ograniczenia integralności:
- unikalność numeru PESEL
- kontrola wartości w kolumnie Plec
- minimalny wiek pacjenta (>= 18 lat)
- walidacja podstawowych danych kontaktowych
--------------------------------------------------------------------
*/

CREATE TABLE Pacjent (
    PacjentID INT IDENTITY(1,1) PRIMARY KEY,
    Imie NVARCHAR(50) NOT NULL,
    Nazwisko NVARCHAR(80) NOT NULL,
    PESEL CHAR(11) NOT NULL UNIQUE,
    DataUrodzenia DATE NOT NULL,
    Plec CHAR(1) NOT NULL,
    Adres NVARCHAR(200) NOT NULL,
    Telefon NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,

    CONSTRAINT CK_Pacjent_Plec
        CHECK (Plec IN ('K','M')),

    CONSTRAINT CK_Pacjent_DataUrodzenia
        CHECK (
            DataUrodzenia >= '1900-01-01'
            AND DataUrodzenia <= DATEADD(YEAR,-18,GETDATE())
        ),

    CONSTRAINT CK_Pacjent_PESEL_Dlugosc
        CHECK (LEN(PESEL) = 11),

    CONSTRAINT CK_Pacjent_PESEL_Cyfry
        CHECK (PESEL NOT LIKE '%[^0-9]%'),

    CONSTRAINT CK_Pacjent_Telefon_Format
        CHECK (
            Telefon IS NULL
            OR (Telefon NOT LIKE '%[^0-9]%' AND LEN(Telefon) BETWEEN 9 AND 15)
        ),

    CONSTRAINT CK_Pacjent_Email_Format
        CHECK (
            Email IS NULL
            OR (Email LIKE '%_@_%._%' AND Email NOT LIKE '% %')
        ),

    CONSTRAINT CK_Pacjent_Min_Jeden_Kontakt
        CHECK (Email IS NOT NULL OR Telefon IS NOT NULL)
);
GO


/*
--------------------------------------------------------------------
TABELA: Uzytkownik
--------------------------------------------------------------------

Konta użytkowników systemu poradni (administrator, lekarz,
pracownik rejestracji). Każde konto posiada przypisaną rolę
systemową określającą poziom uprawnień.

Hasła przechowywane są w postaci skrótu kryptograficznego
(hash).
--------------------------------------------------------------------
*/

CREATE TABLE Uzytkownik (
    UzytkownikID INT IDENTITY(1,1) PRIMARY KEY,
    Imie NVARCHAR(50) NOT NULL,
    Nazwisko NVARCHAR(80) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Telefon NVARCHAR(20) NULL,
    HasloHash VARBINARY(256) NOT NULL,
    RolaID INT NOT NULL,

    CONSTRAINT FK_Uzytkownik_Rola
        FOREIGN KEY (RolaID) 
        REFERENCES Rola(RolaID)
);
GO


/*
--------------------------------------------------------------------
TABELA: Lekarz
--------------------------------------------------------------------

Informacje o lekarzach pracujących w poradni.

Każdy lekarz jest powiązany z kontem użytkownika systemu
oraz posiada unikalny numer prawa wykonywania zawodu (PWZ).
--------------------------------------------------------------------
*/

CREATE TABLE Lekarz (
    LekarzID INT IDENTITY(1,1) PRIMARY KEY,
    UzytkownikID INT NOT NULL UNIQUE,
    NrPWZ NVARCHAR(20) NOT NULL UNIQUE,

    CONSTRAINT FK_Lekarz_Uzytkownik
        FOREIGN KEY (UzytkownikID)
        REFERENCES Uzytkownik(UzytkownikID),
);
GO


/*
--------------------------------------------------------------------
TABELA: Wizyta
--------------------------------------------------------------------

Rejestr wizyt lekarskich.

Zastosowane ograniczenia zapewniają spójność harmonogramu
pracy poradni:

- brak możliwości rejestracji dwóch wizyt lekarza w tym samym czasie
- data utworzenia wizyty wcześniejsza niż data wizyty
- wizyty realizowane wyłącznie w dni robocze
- rozpoczęcie wizyty w interwałach 30-minutowych
- wizyty realizowane w godzinach pracy poradni
- zgodność statusu wizyty ze statusem płatności
--------------------------------------------------------------------
*/

CREATE TABLE Wizyta (
    WizytaID INT IDENTITY(1,1) PRIMARY KEY,
    PacjentID INT NOT NULL,
    LekarzID INT NOT NULL,
    DataWizyty DATETIME2 NOT NULL,
    DataUtworzenia DATETIME2 NOT NULL,
    StatusWizytyID INT NOT NULL,
    StatusPlatnosciID INT NOT NULL,
    TypWizytyID INT NOT NULL,

    CONSTRAINT FK_Wizyta_Pacjent
        FOREIGN KEY (PacjentID) 
        REFERENCES Pacjent(PacjentID),

    CONSTRAINT FK_Wizyta_Lekarz
        FOREIGN KEY (LekarzID) 
        REFERENCES Lekarz(LekarzID),

    CONSTRAINT FK_Wizyta_StatusWizyty
        FOREIGN KEY (StatusWizytyID) 
        REFERENCES StatusWizyty(StatusWizytyID),

    CONSTRAINT FK_Wizyta_StatusPlatnosci
        FOREIGN KEY (StatusPlatnosciID) 
        REFERENCES StatusPlatnosci(StatusPlatnosciID),

    CONSTRAINT FK_Wizyta_TypWizyty
        FOREIGN KEY (TypWizytyID) 
        REFERENCES TypWizyty(TypWizytyID),

    CONSTRAINT UQ_Lekarz_DataWizyty
        UNIQUE (LekarzID, DataWizyty),

    CONSTRAINT CK_Wizyta_Daty
        CHECK (DataUtworzenia < DataWizyty),

    CONSTRAINT CK_Wizyta_DzienRoboczy
        CHECK (DATEPART(WEEKDAY, DataWizyty) BETWEEN 2 AND 6),

    CONSTRAINT CK_Wizyta_Interwal30Min
        CHECK (DATEPART(MINUTE, DataWizyty) IN (0,30)),

    CONSTRAINT CK_Wizyta_GodzinyPracy
        CHECK (DATEPART(HOUR, DataWizyty) BETWEEN 8 AND 15),

    CONSTRAINT CK_Wizyta_StatusLogiczny
        CHECK (NOT (StatusWizytyID = 3 AND StatusPlatnosciID = 2)),

    CONSTRAINT CK_Wizyta_Typ_StatusPlatnosci
        CHECK (NOT (TypWizytyID = 3 AND StatusPlatnosciID = 1))
);
GO


/*
--------------------------------------------------------------------
TABELA: Diagnoza
--------------------------------------------------------------------

Rozpoznania medyczne przypisane do zrealizowanych wizyt.

Diagnozy odwołują się do klasyfikacji ICD-10. Dodatkowo
stosowana jest walidacja zgodności diagnozy z zakresem
specjalizacji lekarza.
--------------------------------------------------------------------
*/

CREATE TABLE Diagnoza (
    DiagnozaID INT IDENTITY(1,1) PRIMARY KEY,
    WizytaID INT NOT NULL UNIQUE,
    ICD10ID INT NOT NULL,
    OpisDodatkowy NVARCHAR(500) NULL,

    CONSTRAINT FK_Diagnoza_Wizyta
        FOREIGN KEY (WizytaID) 
        REFERENCES Wizyta(WizytaID),

    CONSTRAINT FK_Diagnoza_ICD10
        FOREIGN KEY (ICD10ID) 
        REFERENCES ICD10(ICD10ID)
);
GO


/*
--------------------------------------------------------------------
TABELA: Platnosc
--------------------------------------------------------------------

Rejestr płatności powiązanych z wizytami.

Każdej wizycie może odpowiadać maksymalnie jedna płatność.
Kwota przechowywana jest w tabeli w celu zachowania
historycznej wartości usługi niezależnie od zmian w cenniku.

Model zakłada pojedynczą płatność przypisaną do wizyty,
co jest wystarczające dla potrzeb systemu raportowania.
--------------------------------------------------------------------
*/

CREATE TABLE Platnosc (
    PlatnoscID INT IDENTITY(1,1) PRIMARY KEY,
    WizytaID INT NOT NULL UNIQUE,
    Kwota DECIMAL(10,2) NOT NULL,
    DataPlatnosci DATETIME2 NOT NULL,

    CONSTRAINT FK_Platnosc_Wizyta
        FOREIGN KEY (WizytaID) 
        REFERENCES Wizyta(WizytaID),

    CONSTRAINT CK_Platnosc_Kwota
        CHECK (Kwota > 0)
);
GO



/*
====================================================================
IV. TABELE RELACYJNE
====================================================================

Tabele realizujące relacje wiele-do-wielu pomiędzy encjami
systemu (lekarz – specjalizacja, specjalizacja – ICD-10).
====================================================================
*/

CREATE TABLE LekarzSpecjalizacja (
    LekarzID INT NOT NULL,
    SpecjalizacjaID INT NOT NULL,

    CONSTRAINT PK_LekarzSpecjalizacja
        PRIMARY KEY (LekarzID, SpecjalizacjaID),

    CONSTRAINT FK_LS_Lekarz
        FOREIGN KEY (LekarzID) 
        REFERENCES Lekarz(LekarzID),

    CONSTRAINT FK_LS_Specjalizacja
        FOREIGN KEY (SpecjalizacjaID) 
        REFERENCES Specjalizacja(SpecjalizacjaID)
);
GO


CREATE TABLE SpecjalizacjaICD10 (
    SpecjalizacjaID INT NOT NULL,
    ICD10ID INT NOT NULL,

    CONSTRAINT PK_SpecjalizacjaICD10
        PRIMARY KEY (SpecjalizacjaID, ICD10ID),

    CONSTRAINT FK_SpecjalizacjaICD10_Specjalizacja
        FOREIGN KEY (SpecjalizacjaID)
        REFERENCES Specjalizacja(SpecjalizacjaID),

    CONSTRAINT FK_SpecjalizacjaICD10_ICD10
        FOREIGN KEY (ICD10ID)
        REFERENCES ICD10(ICD10ID)
);
GO



/*
====================================================================
V. TABELE RELACYJNE
====================================================================

Tabele realizujące relacje wiele-do-wielu pomiędzy encjami
systemu (lekarz – specjalizacja, specjalizacja – ICD-10).
====================================================================
*/

CREATE INDEX IX_Wizyta_DataWizyty
ON Wizyta (DataWizyty);

CREATE INDEX IX_Wizyta_LekarzID
ON Wizyta (LekarzID);

CREATE INDEX IX_Wizyta_PacjentID
ON Wizyta (PacjentID);

CREATE INDEX IX_Diagnoza_ICD10ID
ON Diagnoza (ICD10ID);

CREATE INDEX IX_Platnosc_DataPlatnosci
ON Platnosc(DataPlatnosci);

CREATE INDEX IX_Wizyta_Pacjent_Data
ON Wizyta(PacjentID, DataWizyty);
