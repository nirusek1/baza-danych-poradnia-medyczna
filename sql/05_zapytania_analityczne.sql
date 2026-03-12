/*
====================================================================
PLIK: 05_zapytania_analityczne.sql

Zestaw zapytań analitycznych wykorzystywanych do:
- weryfikacji danych operacyjnych
- analizy działalności poradni
- przygotowania raportów statystycznych
====================================================================
*/


-- ZAPYTANIE: liczba wizyt
SELECT
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty;


-- ZAPYTANIE: miesięczna liczba wizyt
SELECT
    Rok,
    Miesiac,
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY
    Rok,
    Miesiac
ORDER BY
    Rok,
    Miesiac;


-- ZAPYTANIE: liczba wizyt według typu wizyty
SELECT
    TypWizyty,
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY TypWizyty
ORDER BY LiczbaWizyt DESC;


-- ZAPYTANIE: przychody poradni według miesięcy
SELECT
    Rok,
    Miesiac,
    SUM(Kwota) AS Przychod
FROM vw_FactWizyty
GROUP BY
    Rok,
    Miesiac
ORDER BY
    Rok,
    Miesiac;


-- ZAPYTANIE: przychód generowany przez lekarzy
SELECT
    LekarzImie,
    LekarzNazwisko,
    SUM(Kwota) AS Przychod
FROM vw_FactWizyty
WHERE Kwota IS NOT NULL
GROUP BY
    LekarzImie,
    LekarzNazwisko
ORDER BY Przychod DESC;


-- ZAPYTANIE: lekarze o największym obłożeniu
SELECT
    LekarzImie,
    LekarzNazwisko,
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY
    LekarzImie,
    LekarzNazwisko
ORDER BY LiczbaWizyt DESC;


-- ZAPYTANIE: najczęstsze diagnozy ICD-10
SELECT
    NazwaICD10,
    COUNT(*) AS LiczbaWystapien
FROM vw_FactWizyty
WHERE KodICD10 IS NOT NULL
GROUP BY NazwaICD10
ORDER BY LiczbaWystapien DESC;


-- ZAPYTANIE: pacjenci z największą liczbą wizyt
SELECT
    PacjentImie,
    PacjentNazwisko,
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY
    PacjentImie,
    PacjentNazwisko
ORDER BY LiczbaWizyt DESC;


-- ZAPYTANIE: rozkład wizyt według płci pacjentów
SELECT
    Plec,
    COUNT(*) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY Plec;


-- ZAPYTANIE: wizyty bez diagnozy
SELECT
    CASE
        WHEN KodICD10 IS NULL THEN 'Brak diagnozy'
        ELSE 'Z diagnozą'
    END AS StatusDiagnozy,
    COUNT(DISTINCT WizytaID) AS LiczbaWizyt
FROM vw_FactWizyty
GROUP BY
    CASE
        WHEN KodICD10 IS NULL THEN 'Brak diagnozy'
        ELSE 'Z diagnozą'
    END;