/*
====================================================================
PLIK: 04_dane_testowe.sql

Zestaw danych testowych wykorzystywanych do:
- weryfikacji integralności modelu danych
- testowania procedur i triggerów
- demonstracji zapytań analitycznych i widoków

Zakres danych:
styczeń – czerwiec 2025
====================================================================
*/


/*
--------------------------------------------------------------------
ZAŁOŻENIA DANYCH TESTOWYCH
--------------------------------------------------------------------

LEKARZE
6 lekarzy reprezentujących różne specjalizacje.

PACJENCI
150 pacjentów:
- wiek 18–80 lat
- zróżnicowana płeć
- adresy z Krakowa i okolic.

WIZYTY
Pacjent: maks. 1–2 wizyty miesięcznie.
Godziny pracy poradni: 08:00–15:30.
Minimalny interwał wizyt: 30 minut.

TYPY WIZYT
- konsultacja ~60%
- kontrola ~30%
- teleporada ~10%

STATUSY WIZYT
- zrealizowane ~85–90%
- anulowane ~10–15%

Dane obejmują wyłącznie wizyty historyczne.

PŁATNOŚCI
Kwoty pobierane z tabeli Cennik.
Płatności generowane dla wizyt zrealizowanych.

DIAGNOZY
Diagnozy przypisywane wyłącznie do wizyt
o statusie „zrealizowana”.
Kod ICD10 zgodny ze specjalizacją lekarza.
--------------------------------------------------------------------
*/


/*
--------------------------------------------------------------------
DANE REFERENCYJNE SYSTEMU
--------------------------------------------------------------------
Role użytkowników, statusy wizyt, statusy płatności,
typy wizyt, cennik usług oraz słowniki medyczne.
--------------------------------------------------------------------
*/

INSERT INTO Rola (Nazwa) VALUES
('Administrator'),
('Lekarz'),
('Rejestracja');


INSERT INTO StatusWizyty (Nazwa) VALUES
('Umowiona'),
('Zrealizowana'),
('Anulowana');


INSERT INTO StatusPlatnosci (Nazwa) VALUES
('Nieoplacona'),
('Oplacona'),
('Zwrot');


INSERT INTO TypWizyty (Nazwa) VALUES
('Konsultacja'),
('Kontrola'),
('Teleporada');


INSERT INTO Cennik VALUES
(1,250),(2,200),(3,150);


INSERT INTO Specjalizacja (Nazwa) VALUES
('Kardiologia'),
('Dermatologia'),
('Ortopedia'),
('Endokrynologia'),
('Medycyna rodzinna'),
('Neurologia');


INSERT INTO ICD10 (Kod, Nazwa) VALUES
('I10', 'Nadciśnienie pierwotne'),
('I20', 'Dławica piersiowa'),
('I50', 'Niewydolność serca'),
('E11', 'Cukrzyca typu 2'),
('E03', 'Niedoczynność tarczycy'),
('J45', 'Astma'),
('J06', 'Ostre zapalenie górnych dróg oddechowych'),
('M54', 'Ból grzbietu'),
('M17', 'Choroba zwyrodnieniowa kolana'),
('L20', 'Atopowe zapalenie skóry'),
('L40', 'Łuszczyca'),
('K21', 'Refluks żołądkowo-przełykowy'),
('K29', 'Zapalenie błony śluzowej żołądka'),
('N39', 'Zakażenie układu moczowego'),
('F41', 'Zaburzenia lękowe'),
('G43', 'Migrena'),
('R51', 'Ból głowy'),
('Z00', 'Badanie ogólne'),
('Z01', 'Inne badania specjalistyczne'),
('I11','Choroba nadciśnieniowa z zajęciem serca'),
('I25','Przewlekła choroba niedokrwienna serca'),
('I48','Migotanie przedsionków'),
('I49','Zaburzenia rytmu serca'),
('I34','Niewydolność zastawki mitralnej'),
('L30','Zapalenie skóry nieokreślone'),
('L70','Trądzik'),
('B35','Grzybica skóry'),
('L50','Pokrzywka'),
('D23','Niezłośliwy nowotwór skóry'),
('M16','Choroba zwyrodnieniowa biodra'),
('M51','Inne choroby krążka międzykręgowego'),
('M75','Uszkodzenia barku'),
('S83','Skręcenie i naderwanie kolana'),
('M77','Zapalenie nadkłykcia (łokieć tenisisty)'),
('E05','Nadczynność tarczycy'),
('E66','Otyłość'),
('E78','Zaburzenia lipidowe'),
('E28','Zaburzenia czynności jajników'),
('E23','Zaburzenia przysadki mózgowej'),
('G40','Padaczka'),
('G44','Inne zespoły bólu głowy'),
('G56','Zespół cieśni nadgarstka'),
('G62','Polineuropatia'),
('F07','Zaburzenia funkcji poznawczych'),
('J00','Ostre zapalenie nosa'),
('J02','Ostre zapalenie gardła'),
('J20','Ostre zapalenie oskrzeli'),
('R07','Ból w klatce piersiowej'),
('Z71','Porada lekarska');



/*
--------------------------------------------------------------------
UŻYTKOWNICY SYSTEMU
--------------------------------------------------------------------
Konta systemowe personelu administracyjnego, rejestracji
oraz lekarzy.
--------------------------------------------------------------------
*/

INSERT INTO Uzytkownik (Imie, Nazwisko, Email, Telefon, HasloHash, RolaID)
VALUES
('Anna', 'Nowak', 'admin@poradnia.pl', '500100100', 0x010203, 1),
('Katarzyna', 'Mazur', 'rejestracja@poradnia.pl', '500200200', 0x010203, 3),
('Michał', 'Kowalski', 'm.kowalski@poradnia.pl', '501111111', 0x010203, 2),
('Ewa', 'Zielińska', 'e.zielinska@poradnia.pl', '502222222', 0x010203, 2),
('Tomasz', 'Lewandowski', 't.lewandowski@poradnia.pl', '503333333', 0x010203, 2),
('Magdalena', 'Kaczmarek', 'm.kaczmarek@poradnia.pl', '504444444', 0x010203, 2),
('Karol', 'Witkowski', 'k.witkowski@poradnia.pl', '505555555', 0x010203, 2),
('Anna','Mazur','a.mazur@poradnia.pl','506666666',0x010203,2);



/*
--------------------------------------------------------------------
LEKARZE
--------------------------------------------------------------------
Personel medyczny powiązany z kontami systemowymi.
--------------------------------------------------------------------
*/

INSERT INTO Lekarz (UzytkownikID, NrPWZ)
VALUES
(3, 'PWZ10001'),
(4, 'PWZ10002'),
(5, 'PWZ10003'),
(6, 'PWZ10004'),
(7, 'PWZ10005'),
(8, 'PWZ10006');



/*
--------------------------------------------------------------------
SPECJALIZACJE LEKARZY
--------------------------------------------------------------------
Powiązanie lekarzy z ich specjalizacjami medycznymi.
--------------------------------------------------------------------
*/

INSERT INTO LekarzSpecjalizacja (LekarzID, SpecjalizacjaID)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 6),
(6, 5);



/*
--------------------------------------------------------------------
MAPOWANIE ICD10 DO SPECJALIZACJI
--------------------------------------------------------------------
Zakres kodów ICD10 przypisanych do specjalizacji
wykorzystywany podczas walidacji diagnoz.
--------------------------------------------------------------------
*/

INSERT INTO SpecjalizacjaICD10 (SpecjalizacjaID, ICD10ID) 
VALUES
(1,1),(1,2),(1,3),(1,21),(1,22),(1,23),(1,24),(1,25),
(2,10),(2,11),(2,26),(2,27),(2,28),(2,29),(2,30),
(3,8),(3,9),(3,31),(3,32),(3,33),(3,34),(3,35),
(4,4),(4,5),(4,36),(4,37),(4,38),(4,39),(4,40),
(5,16),(5,41),(5,42),(5,43),(5,44),(5,45),
(6,6),(6,7),(6,12),(6,13),(6,14),(6,15),
(6,18),(6,19),(6,20),(6,46),(6,47),(6,48),(6,49),(6,50);



/*
--------------------------------------------------------------------
DANE PACJENTÓW
--------------------------------------------------------------------
Zestaw pacjentów wykorzystywany do symulacji
rzeczywistego obciążenia systemu.
--------------------------------------------------------------------
*/

INSERT INTO Pacjent 
(Imie, Nazwisko, PESEL, DataUrodzenia, Plec, Adres, Telefon, Email)
VALUES
('Maria','Kowalczyk','54010112345','1954-01-01','K','ul. Słoneczna 12, 30-001 Kraków','600100101','m.kowalczyk@email.pl'),
('Anna','Nowicka','62031523456','1962-03-15','K','ul. Zielona 5, 30-002 Kraków','600100102','a.nowicka@email.pl'),
('Katarzyna','Wiśniewska','75072034567','1975-07-20','K','ul. Leśna 18, 30-003 Kraków','600100103','k.wisniewska@email.pl'),
('Ewa','Wójcik','82090245678','1982-09-02','K','ul. Lipowa 7, 30-004 Kraków','600100104','e.wojcik@email.pl'),
('Magdalena','Kamińska','91061056789','1991-06-10','K','ul. Polna 22, 30-005 Kraków','600100105','m.kaminska@email.pl'),
('Agnieszka','Lewandowska','99041267890','1999-04-12','K','ul. Ogrodowa 9, 30-006 Kraków','600100106','a.lewandowska@email.pl'),
('Julia','Dąbrowska','04120178901','2004-12-01','K','ul. Wiosenna 3, 30-007 Kraków','600100107','j.dabrowska@email.pl'),
('Natalia','Kaczmarek','03071490123','2003-07-14','K','ul. Jasna 11, 30-009 Kraków','600100109','n.kaczmarek@email.pl'),
('Barbara','Zielińska','58061512345','1958-06-15','K','ul. Różana 2, 30-011 Kraków','600300101','b.zielinska@email.pl'),
('Teresa','Szymańska','67090123456','1967-09-01','K','ul. Kwiatowa 5, 30-012 Kraków','600300102','t.szymanska@email.pl'),
('Karolina','Woźniak','88021134567','1988-02-11','K','ul. Akacjowa 8, 30-013 Kraków','600300103','k.wozniak@email.pl'),
('Joanna','Wieczorek','93091867890','1993-09-18','K','ul. Tulipanowa 9, 30-016 Kraków','600300106','j.wieczorek@email.pl'),
('Patrycja','Maj','01010189012','2001-01-01','K','ul. Wrzosowa 1, 30-018 Kraków','600300108','p.maj@email.pl'),
('Monika','Czarnecka','94030301234','1994-03-03','K','ul. Klonowa 20, 30-020 Kraków','600300110','m.czarnecka@email.pl'),
('Oliwia','Mazur','06082234567','2006-08-22','K','ul. Brzozowa 6, 30-010 Kraków','600400110','o.mazur@email.pl'),
('Elżbieta','Baran','65040211111','1965-04-02','K','ul. Radosna 4, 30-025 Kraków','601000001','e.baran@email.pl'),
('Danuta','Walczak','72011822222','1972-01-18','K','ul. Graniczna 9, 30-026 Kraków','601000002','d.walczak@email.pl'),
('Sylwia','Pawłowska','85072333333','1985-07-23','K','ul. Tęczowa 15, 30-027 Kraków','601000003','s.pawlowska@email.pl'),
('Martyna','Adamska','95051244444','1995-05-12','K','ul. Jesionowa 7, 30-028 Kraków','601000004','m.adamska@email.pl'),
('Paulina','Rutkowska','98030555555','1998-03-05','K','ul. Północna 3, 30-029 Kraków','601000005','p.rutkowska@email.pl'),
('Weronika','Chmielewska','01090766666','2001-09-07','K','ul. Wodna 6, 30-030 Kraków','601000006','w.chmielewska@email.pl'),
('Beata','Bąk','79021477777','1979-02-14','K','ul. Łąkowa 8, 30-031 Kraków','601000007','b.bak@email.pl'),
('Renata','Górska','68083088888','1968-08-30','K','ul. Szkolna 12, 30-032 Kraków','601000008','r.gorska@email.pl'),
('Iwona','Sikora','90041999999','1990-04-19','K','ul. Mostowa 10, 30-033 Kraków','601000009','i.sikora@email.pl'),
('Aleksandra','Wrona','02011112121','2002-01-11','K','ul. Błękitna 5, 30-034 Kraków','601000010','a.wrona@email.pl'),
('Jan','Kowalski','50021012345','1950-02-10','M','ul. Słoneczna 13, 30-001 Kraków','600200101','j.kowalski@email.pl'),
('Piotr','Nowak','68040523456','1968-04-05','M','ul. Zielona 6, 30-002 Kraków','600200102','p.nowak@email.pl'),
('Andrzej','Wiśniewski','73091934567','1973-09-19','M','ul. Leśna 19, 30-003 Kraków','600200103','a.wisniewski@email.pl'),
('Marek','Wójcik','80112545678','1980-11-25','M','ul. Lipowa 8, 30-004 Kraków','600200104','m.wojcik@email.pl'),
('Tomasz','Kamiński','90030156789','1990-03-01','M','ul. Polna 23, 30-005 Kraków','600200105','t.kaminski@email.pl'),
('Paweł','Lewandowski','97061567890','1997-06-15','M','ul. Ogrodowa 10, 30-006 Kraków','600200106','p.lewandowski@email.pl'),
('Adam','Kaczmarek','02022390123','2002-02-23','M','ul. Jasna 12, 30-009 Kraków','600200109','a.kaczmarek@email.pl'),
('Michał','Krawczyk','79072345678','1979-07-23','M','ul. Morelowa 4, 30-014 Kraków','600300104','m.krawczyk@email.pl'),
('Łukasz','Król','85041256789','1985-04-12','M','ul. Lawendowa 6, 30-015 Kraków','600300105','l.krol@email.pl'),
('Damian','Lis','96052078901','1996-05-20','M','ul. Chabrowa 3, 30-017 Kraków','600300107','d.lis@email.pl'),
('Sebastian','Olszewski','87070790123','1987-07-07','M','ul. Jodłowa 14, 30-019 Kraków','600300109','s.olszewski@email.pl'),
('Karol','Witkowski','78041145678','1978-04-11','M','ul. Dębowa 21, 30-021 Kraków','600400111','k.witkowski@email.pl'),
('Marcin','Zając','92053056789','1992-05-30','M','ul. Topolowa 7, 30-022 Kraków','600400112','m.zajac@email.pl'),
('Rafał','Pawlak','00021867890','2000-02-18','M','ul. Grabowa 9, 30-023 Kraków','600400113','r.pawlak@email.pl'),
('Krzysztof','Michalski','65090178901','1965-09-01','M','ul. Świerkowa 3, 30-024 Kraków','600400114','k.michalski@email.pl'),
('Grzegorz','Jaworski','63070713131','1963-07-07','M','ul. Krótka 2, 30-035 Kraków','602000001','g.jaworski@email.pl'),
('Zbigniew','Malinowski','59051514141','1959-05-15','M','ul. Długa 18, 30-036 Kraków','602000002','z.malinowski@email.pl'),
('Artur','Kubiak','78030215151','1978-03-02','M','ul. Zaciszna 9, 30-037 Kraków','602000003','a.kubiak@email.pl'),
('Bartosz','Piasecki','88092416161','1988-09-24','M','ul. Wąska 6, 30-038 Kraków','602000004','b.piasecki@email.pl'),
('Dawid','Marciniak','93011817171','1993-01-18','M','ul. Widokowa 14, 30-039 Kraków','602000005','d.marciniak@email.pl'),
('Kamil','Tomczak','99060518181','1999-06-05','M','ul. Rumiankowa 3, 30-040 Kraków','602000006','k.tomczak@email.pl'),
('Norbert','Kozłowski','04021219191','2004-02-12','M','ul. Jagodowa 7, 30-041 Kraków','602000007','n.kozlowski@email.pl'),
('Wojciech','Szewczyk','76092120202','1976-09-21','M','ul. Malinowa 11, 30-042 Kraków','602000008','w.szewczyk@email.pl'),
('Radosław','Borkowski','82041121212','1982-04-11','M','ul. Cedrowa 4, 30-043 Kraków','602000009','r.borkowski@email.pl'),
('Szymon','Szczepański','91071022222','1991-07-10','M','ul. Braterska 13, 30-044 Kraków','602000010','s.szczepanski@email.pl'),
('Halina','Urban','55020323232','1955-02-03','K','ul. Pogodna 5, 30-045 Kraków','603000001','h.urban@email.pl'),
('Janina','Kaczor','60091424242','1960-09-14','K','ul. Kręta 8, 30-046 Kraków','603000002','j.kaczor@email.pl'),
('Dominika','Zawadzka','97030125252','1997-03-01','K','ul. Jasnogórska 4, 30-047 Kraków','603000003','d.zawadzka@email.pl'),
('Natalia','Michalak','02081226262','2002-08-12','K','ul. Spokojna 6, 30-048 Kraków','603000004','n.michalak@email.pl'),
('Henryk','Pietrzak','52051927272','1952-05-19','M','ul. Wesoła 10, 30-049 Kraków','603000005','h.pietrzak@email.pl'),
('Jerzy','Cieślak','61072428282','1961-07-24','M','ul. Parkowa 3, 30-050 Kraków','603000006','j.cieslak@email.pl'),
('Maciej','Włodarczyk','84010529292','1984-01-05','M','ul. Nowa 2, 30-051 Kraków','603000007','m.wlodarczyk@email.pl'),
('Łukasz','Stępień','96031830303','1996-03-18','M','ul. Zielna 15, 30-052 Kraków','603000008','l.stepien@email.pl'),
('Adrian','Kamiński','03091031313','2003-09-10','M','ul. Poranna 9, 30-053 Kraków','603000009','a.kaminski@email.pl'),
('Marzena','Lisowska','87042632323','1987-04-26','K','ul. Zachodnia 7, 30-054 Kraków','603000010','m.lisowska@email.pl'),
('Michał','Bednarczyk','85031254123','1985-03-12','M','ul. Fiołkowa 2, 30-145 Kraków','605000001','m.bednarczyk@demo.pl'),
('Klaudia','Sikorska','92072165234','1992-07-21','K','ul. Storczykowa 4, 30-146 Kraków','605000002','k.sikorska@demo.pl'),
('Paweł','Mazur','78091576345','1978-09-15','M','ul. Cisowa 6, 32-020 Wieliczka','605000003','p.mazur@demo.pl'),
('Alicja','Kaczmarczyk','90010187456','1990-01-01','K','ul. Ogrodowa 3, 32-050 Skawina','605000004','a.kaczmarczyk@demo.pl'),
('Robert','Duda','72051198567','1972-05-11','M','ul. Wiśniowa 9, 32-080 Zabierzów','605000005','r.duda@demo.pl'),
('Natalia','Pawlak','04040419678','2004-04-04','K','ul. Sadowa 5, 32-005 Niepołomice','605000006','n.pawlak@demo.pl'),
('Tomasz','Wilk','65082320789','1965-08-23','M','ul. Koralowa 7, 30-147 Kraków','605000007','t.wilk@demo.pl'),
('Izabela','Witkowska','88060631890','1988-06-06','K','ul. Rubinowa 7, 32-087 Zielonki','605000008','i.witkowska@demo.pl'),
('Łukasz','Baranowski','91021742901','1991-02-17','M','ul. Perłowa 11, 32-031 Mogilany','605000009','l.baranowski@demo.pl'),
('Karolina','Ostrowska','97093053012','1997-09-30','K','ul. Turkusowa 4, 30-148 Kraków','605000010','k.ostrowska@demo.pl'),
('Mateusz','Michalik','84031564123','1984-03-15','M','ul. Bratnia 6, 30-149 Kraków','605000011','m.michalik@demo.pl'),
('Magda','Kowal','93081275234','1993-08-12','K','ul. Gołębia 9, 32-020 Wieliczka','605000012','m.kowal@demo.pl'),
('Sebastian','Piotrowski','75062286345','1975-06-22','M','ul. Orla 3, 32-050 Skawina','605000013','s.piotrowski@demo.pl'),
('Ewelina','Grabowska','99010197456','1999-01-01','K','ul. Sokola 8, 32-080 Zabierzów','605000014','e.grabowska@demo.pl'),
('Dariusz','Kurek','68050518567','1968-05-05','M','ul. Żurawia 10, 30-150 Kraków','605000015','d.kurek@demo.pl'),
('Weronika','Lis','03071229678','2003-07-12','K','ul. Łabędzia 14, 32-005 Niepołomice','605000016','w.lis@demo.pl'),
('Arkadiusz','Sadowski','89092030789','1989-09-20','M','ul. Borsucza 5, 30-151 Kraków','605000017','a.sadowski@demo.pl'),
('Patrycja','Kania','94030341890','1994-03-03','K','ul. Żytnia 7, 32-087 Zielonki','605000018','p.kania@demo.pl'),
('Marcin','Czarnecki','81081152901','1981-08-11','M','ul. Żurawinowa 2, 32-031 Mogilany','605000019','m.czarnecki@demo.pl'),
('Aleksandra','Nowakowska','96051563012','1996-05-15','K','ul. Skalna 9, 30-152 Kraków','605000020','a.nowakowska@demo.pl'),
('Krzysztof','Jabłoński','79010174123','1979-01-01','M','ul. Górska 3, 32-020 Wieliczka','605000021','k.jablonski@demo.pl'),
('Monika','Kubiak','87062285234','1987-06-22','K','ul. Tatrzańska 4, 32-050 Skawina','605000022','m.kubiak@demo.pl'),
('Rafał','Chmura','92050596345','1992-05-05','M','ul. Pienińska 6, 30-153 Kraków','605000023','r.chmura@demo.pl'),
('Natalia','Bąk','98081217456','1998-08-12','K','ul. Sudecka 8, 32-080 Zabierzów','605000024','n.bak@demo.pl'),
('Damian','Wrona','85031528567','1985-03-15','M','ul. Mazowiecka 10, 32-005 Niepołomice','605000025','d.wrona@demo.pl'),
('Justyna','Urban','90072039678','1990-07-20','K','ul. Śląska 12, 30-154 Kraków','605000026','j.urban@demo.pl'),
('Artur','Gajda','76091150789','1976-09-11','M','ul. Lubelska 14, 32-087 Zielonki','605000027','a.gajda@demo.pl'),
('Karolina','Rybak','93043061890','1993-04-30','K','ul. Wielkopolska 18, 32-031 Mogilany','605000028','k.rybak@demo.pl'),
('Bartosz','Olszak','88021872901','1988-02-18','M','ul. Pogodna 5, 30-155 Kraków','605000029','b.olszak@demo.pl'),
('Dominika','Zielińska','97092583012','1997-09-25','K','ul. Kręta 8, 32-020 Wieliczka','605000030','d.zielinska2@demo.pl'),
('Adam','Sroka','74061594123','1974-06-15','M','ul. Spokojna 4, 32-050 Skawina','605000081','a.sroka@demo.pl'),
('Ewa','Majewska','96082105234','1996-08-21','K','ul. Wesoła 7, 32-080 Zabierzów','605000082','e.majewska@demo.pl'),
('Marcin','Kaczor','82031216345','1982-03-12','M','ul. Parkowa 3, 32-005 Niepołomice','605000083','m.kaczor@demo.pl'),
('Sandra','Bielecka','99010327456','1999-01-03','K','ul. Zielna 15, 30-156 Kraków','605000084','s.bielecka@demo.pl'),
('Piotr','Tomczyk','70090538567','1970-09-05','M','ul. Poranna 9, 32-087 Zielonki','605000085','p.tomczyk@demo.pl'),
('Joanna','Zawisza','88041249678','1988-04-12','K','ul. Zachodnia 7, 32-031 Mogilany','605000086','j.zawisza@demo.pl'),
('Łukasz','Rataj','92011150789','1992-01-11','M','ul. Zaciszna 2, 30-157 Kraków','605000087','l.rataj@demo.pl'),
('Magdalena','Cieśla','85073061890','1985-07-30','K','ul. Brzozowa 9, 32-020 Wieliczka','605000088','m.ciesla@demo.pl'),
('Kamil','Pietrzak','97041472901','1997-04-14','M','ul. Klonowa 12, 32-050 Skawina','605000089','k.pietrzak@demo.pl'),
('Agnieszka','Kłos','91091883012','1991-09-18','K','ul. Dębowa 8, 30-158 Kraków','605000090','a.klos@demo.pl'),
('Hubert','Konieczny','86031594123','1986-03-15','M','ul. Spacerowa 4, 30-159 Kraków','605000091','h.konieczny@demo.pl'),
('Martyna','Laskowska','95072205234','1995-07-22','K','ul. Leśna 7, 32-020 Wieliczka','605000092','m.laskowska@demo.pl'),
('Grzegorz','Puchała','72010416345','1972-01-04','M','ul. Polna 11, 32-050 Skawina','605000093','g.puchala@demo.pl'),
('Paulina','Kurek','99091827456','1999-09-18','K','ul. Słoneczna 9, 32-080 Zabierzów','605000094','p.kurek@demo.pl'),
('Mariusz','Walczak','68061138567','1968-06-11','M','ul. Lipowa 3, 32-005 Niepołomice','605000095','m.walczak@demo.pl'),
('Natalia','Sowa','03022549678','2003-02-25','K','ul. Brzozowa 6, 32-087 Zielonki','605000096','n.sowa@demo.pl'),
('Krzysztof','Głowacki','75083050789','1975-08-30','M','ul. Wrzosowa 14, 32-031 Mogilany','605000097','k.glowacki@demo.pl'),
('Wiktoria','Tomala','01071461890','2001-07-14','K','ul. Błękitna 8, 30-160 Kraków','605000098','w.tomala@demo.pl'),
('Szymon','Zięba','84051972901','1984-05-19','M','ul. Graniczna 5, 32-020 Wieliczka','605000099','s.zieba@demo.pl'),
('Anna','Orzech','92031283012','1992-03-12','K','ul. Tęczowa 2, 32-050 Skawina','605000100','a.orzech@demo.pl'),
('Tadeusz','Kaczorowski','65010194123','1965-01-01','M','ul. Długa 18, 30-161 Kraków','605000101','t.kaczorowski@demo.pl'),
('Sandra','Klimczak','97041105234','1997-04-11','K','ul. Parkowa 6, 32-080 Zabierzów','605000102','s.klimczak@demo.pl'),
('Adrian','Buczek','90072216345','1990-07-22','M','ul. Mostowa 4, 32-005 Niepołomice','605000103','a.buczek@demo.pl'),
('Eliza','Kopeć','88091927456','1988-09-19','K','ul. Jasna 9, 32-087 Zielonki','605000104','e.kopec@demo.pl'),
('Rafał','Mazurek','76060438567','1976-06-04','M','ul. Krótka 2, 32-031 Mogilany','605000105','r.mazurek@demo.pl'),
('Karina','Sobczak','96021849678','1996-02-18','K','ul. Zielona 12, 30-162 Kraków','605000106','k.sobczak@demo.pl'),
('Michał','Kalinowski','82093050789','1982-09-30','M','ul. Szkolna 7, 32-020 Wieliczka','605000107','m.kalinowski@demo.pl'),
('Alicja','Rogala','04051561890','2004-05-15','K','ul. Różana 5, 32-050 Skawina','605000108','a.rogala@demo.pl'),
('Dominik','Górny','91030872901','1991-03-08','M','ul. Wodna 11, 30-163 Kraków','605000109','d.gorny@demo.pl'),
('Monika','Pasternak','85062183012','1985-06-21','K','ul. Zaciszna 3, 32-080 Zabierzów','605000110','m.pasternak@demo.pl'),
('Igor','Wesołowski','73051294123','1973-05-12','M','ul. Ogrodowa 10, 32-005 Niepołomice','605000111','i.wesolowski@demo.pl'),
('Edyta','Szulc','98010405234','1998-01-04','K','ul. Chabrowa 8, 32-087 Zielonki','605000112','e.szulc@demo.pl'),
('Łukasz','Cichy','87091316345','1987-09-13','M','ul. Jesionowa 4, 32-031 Mogilany','605000113','l.cichy@demo.pl'),
('Beata','Kruk','69020727456','1969-02-07','K','ul. Świerkowa 6, 30-164 Kraków','605000114','b.kruk@demo.pl'),
('Przemysław','Rusek','95052238567','1995-05-22','M','ul. Kwiatowa 9, 32-020 Wieliczka','605000115','p.rusek@demo.pl'),
('Julia','Nowosielska','02091549678','2002-09-15','K','ul. Klonowa 3, 32-050 Skawina','605000116','j.nowosielska@demo.pl'),
('Bartłomiej','Kozioł','80040450789','1980-04-04','M','ul. Pogodna 7, 30-165 Kraków','605000117','b.koziol@demo.pl'),
('Katarzyna','Żak','93061861890','1993-06-18','K','ul. Poranna 12, 32-080 Zabierzów','605000118','k.zak@demo.pl'),
('Marcel','Błaszczyk','01031172901','2001-03-11','M','ul. Malinowa 5, 32-005 Niepołomice','605000119','m.blaszczyk@demo.pl'),
('Agata','Kania','97010283012','1997-01-02','K','ul. Dębowa 2, 32-087 Zielonki','605000120','a.kania2@demo.pl'),
('Wojciech','Olejniczak','66071994123','1966-07-19','M','ul. Wesoła 4, 32-031 Mogilany','605000121','w.olejniczak@demo.pl'),
('Natalia','Bartosik','94052205234','1994-05-22','K','ul. Braterska 6, 30-166 Kraków','605000122','n.bartosik@demo.pl'),
('Tomasz','Madej','78022816345','1978-02-28','M','ul. Cedrowa 10, 32-020 Wieliczka','605000123','t.madej@demo.pl'),
('Aleksandra','Sikora','90070727456','1990-07-07','K','ul. Lawendowa 3, 32-050 Skawina','605000124','a.sikora2@demo.pl'),
('Daniel','Kasperski','85011338567','1985-01-13','M','ul. Grabowa 8, 30-167 Kraków','605000125','d.kasperski@demo.pl'),
('Magdalena','Filipek','02081249678','2002-08-12','K','ul. Rubinowa 2, 32-080 Zabierzów','605000126','m.filipek@demo.pl'),
('Sebastian','Róg','77052150789','1977-05-21','M','ul. Wiśniowa 6, 32-005 Niepołomice','605000127','s.rog@demo.pl'),
('Paulina','Adamczyk','95041461890','1995-04-14','K','ul. Sadowa 12, 32-087 Zielonki','605000128','p.adamczyk@demo.pl'),
('Michał','Kołodziej','89090572901','1989-09-05','M','ul. Górna 3, 32-031 Mogilany','605000129','m.kolodziej@demo.pl'),
('Ewa','Janik','96030383012','1996-03-03','K','ul. Radosna 7, 30-168 Kraków','605000130','e.janik@demo.pl'),
('Patryk','Szymczak','84071194123','1984-07-11','M','ul. Akacjowa 9, 32-020 Wieliczka','605000131','p.szymczak@demo.pl'),
('Karolina','Krupa','98021505234','1998-02-15','K','ul. Tulipanowa 4, 32-050 Skawina','605000132','k.krupa@demo.pl'),
('Dawid','Stasiak','91063016345','1991-06-30','M','ul. Topolowa 11, 30-169 Kraków','605000133','d.stasiak@demo.pl'),
('Sylwia','Borek','87040927456','1987-04-09','K','ul. Zaciszna 5, 32-080 Zabierzów','605000134','s.borek@demo.pl'),
('Kamil','Dąbek','03012238567','2003-01-22','M','ul. Zielna 3, 32-005 Niepołomice','605000135','k.dabek@demo.pl'),
('Anna','Kozak','92081449678','1992-08-14','K','ul. Parkowa 9, 32-087 Zielonki','605000136','a.kozak@demo.pl'),
('Mateusz','Polak','75031850789','1975-03-18','M','ul. Wrzosowa 6, 32-031 Mogilany','605000137','m.polak@demo.pl'),
('Izabela','Kaczmarek','99052161890','1999-05-21','K','ul. Słoneczna 14, 30-170 Kraków','605000138','i.kaczmarek2@demo.pl'),
('Radosław','Czajka','81011172901','1981-01-11','M','ul. Leśna 15, 32-020 Wieliczka','605000139','r.czajka@demo.pl'),
('Martyna','Kowalik','97073083012','1997-07-30','K','ul. Ogrodowa 18, 32-050 Skawina','605000140','m.kowalik@demo.pl');



/*
--------------------------------------------------------------------
DANE WIZYT
--------------------------------------------------------------------
Historia wizyt pacjentów w okresie
styczeń – czerwiec 2025.
--------------------------------------------------------------------
*/

INSERT INTO Wizyta
(PacjentID, LekarzID, DataWizyty, DataUtworzenia, StatusWizytyID, StatusPlatnosciID, TypWizytyID)
VALUES
(17,6,'2025-01-02 08:00','2024-12-19',2,2,1),
(4,2,'2025-01-02 09:00','2024-12-29',2,2,1),
(29,6,'2025-01-02 10:30','2024-12-18',2,2,2),
(8,4,'2025-01-03 08:30','2024-12-22',2,2,1),
(41,6,'2025-01-03 10:00','2025-01-01',2,2,3),
(12,1,'2025-01-06 08:00','2024-12-27',2,2,2),
(33,3,'2025-01-06 09:30','2024-12-30',3,1,1),
(25,2,'2025-01-06 11:00','2025-01-04',3,3,3),
(52,4,'2025-01-07 08:00','2024-12-23',2,2,1),
(6,3,'2025-01-07 09:00','2024-12-28',2,2,2),
(44,1,'2025-01-08 08:30','2024-12-26',2,2,1),
(19,6,'2025-01-08 10:00','2025-01-06',2,2,3),
(2,2,'2025-01-08 11:30','2024-12-30',2,2,1),
(37,3,'2025-01-09 08:00','2024-12-20',2,2,2),
(15,4,'2025-01-09 09:30','2024-12-21',2,2,1),
(58,1,'2025-01-09 11:00','2024-12-25',2,2,2),
(21,2,'2025-01-10 08:00','2024-12-31',2,2,1),
(48,3,'2025-01-10 09:30','2024-12-24',2,2,1),
(9,5,'2025-01-10 11:00','2025-01-08',3,3,3),
(31,4,'2025-01-13 08:00','2024-12-30',2,2,2),
(14,1,'2025-01-13 09:30','2024-12-22',2,2,1),
(55,6,'2025-01-14 08:30','2024-12-29',2,2,2),
(11,2,'2025-01-14 10:00','2025-01-12',3,1,1),
(40,6,'2025-01-15 08:00','2024-12-27',2,2,1),
(23,4,'2025-01-15 09:30','2024-12-28',2,2,2),
(7,6,'2025-01-16 08:00','2025-01-14',2,2,3),
(50,3,'2025-01-16 09:30','2024-12-23',2,2,1),
(27,2,'2025-01-17 08:00','2024-12-31',2,2,1),
(35,4,'2025-01-17 09:30','2024-12-26',3,1,2),
(1,1,'2025-01-20 08:00','2025-01-07',2,2,2),
(46,3,'2025-01-20 09:30','2024-12-29',2,2,1),
(18,2,'2025-01-22 08:30','2025-01-10',2,2,1),
(60,4,'2025-01-22 10:00','2024-12-30',2,2,2),
(13,5,'2025-01-24 08:00','2025-01-22',2,2,3),
(34,1,'2025-01-24 09:30','2024-12-31',3,1,1),
(42,3,'2025-01-27 08:00','2025-01-14',2,2,2),
(5,4,'2025-01-27 09:30','2025-01-16',2,2,1),
(24,2,'2025-01-29 08:30','2025-01-20',2,2,1),
(16,1,'2025-01-29 10:00','2025-01-17',2,2,2),
(42,5,'2025-01-21 08:00:00','2025-01-10',2,2,1),
(49,5,'2025-01-28 09:30:00','2025-01-15',2,2,2),
(16,5,'2025-01-31 08:30:00','2025-01-18',2,2,1),
(4, 6, '2025-02-03 08:00:00', '2025-01-20', 2, 2, 1),
(15, 4, '2025-02-03 09:00:00', '2025-01-22', 2, 2, 2),
(33, 2, '2025-02-03 10:30:00', '2025-01-25', 2, 2, 1),
(1, 1, '2025-02-04 08:00:00', '2025-01-23', 2, 2, 2),
(18, 6, '2025-02-04 09:30:00', '2025-01-28', 2, 2, 3),
(40, 3, '2025-02-04 11:00:00', '2025-01-30', 2, 2, 1),
(9, 4, '2025-02-05 08:30:00', '2025-01-21', 2, 2, 2),
(22, 2, '2025-02-05 10:00:00', '2025-01-24', 2, 2, 1),
(52, 1, '2025-02-06 08:00:00', '2025-01-26', 2, 2, 2),
(37, 3, '2025-02-06 09:30:00', '2025-01-29', 2, 2, 1),
(12, 6, '2025-02-07 08:00:00', '2025-01-31', 3, 1, 1),
(45, 5, '2025-02-07 09:30:00', '2025-01-30', 2, 2, 1),
(6, 4, '2025-02-10 08:00:00', '2025-02-01', 2, 2, 2),
(27, 3, '2025-02-10 09:30:00', '2025-01-30', 2, 2, 2),
(51, 6, '2025-02-10 11:00:00', '2025-02-02', 2, 2, 3),
(17, 1, '2025-02-11 08:00:00', '2025-01-30', 2, 2, 2),
(24, 2, '2025-02-11 09:30:00', '2025-02-01', 2, 2, 1),
(30, 4, '2025-02-12 08:00:00', '2025-02-02', 2, 2, 2),
(58, 6, '2025-02-12 09:30:00', '2025-02-05', 2, 2, 3),
(34, 3, '2025-02-13 08:00:00', '2025-02-01', 2, 2, 2),
(21, 6, '2025-02-13 09:30:00', '2025-02-06', 2, 2, 1),
(2, 2, '2025-02-14 08:00:00', '2025-02-04', 3, 1, 1),
(16, 1, '2025-02-17 08:00:00', '2025-02-07', 2, 2, 2),
(29, 3, '2025-02-17 09:30:00', '2025-02-08', 2, 2, 1),
(54, 6, '2025-02-17 11:00:00', '2025-02-10', 2, 2, 1),
(5, 4, '2025-02-18 08:00:00', '2025-02-07', 2, 2, 2),
(41, 5, '2025-02-18 09:30:00', '2025-02-09', 2, 2, 1),
(10, 4, '2025-02-19 08:00:00', '2025-02-08', 2, 2, 2),
(26, 6, '2025-02-19 09:30:00', '2025-02-10', 2, 2, 1),
(38, 3, '2025-02-20 08:00:00', '2025-02-11', 2, 2, 2),
(47, 6, '2025-02-20 09:30:00', '2025-02-12', 2, 2, 3),
(3, 4, '2025-02-21 08:00:00', '2025-02-12', 2, 2, 2),
(49, 5, '2025-02-21 09:30:00', '2025-02-13', 2, 2, 2),
(7, 6, '2025-02-24 08:00:00', '2025-02-15', 3, 1, 1),
(31, 3, '2025-02-24 09:30:00', '2025-02-16', 2, 2, 1),
(55, 1, '2025-02-25 08:00:00', '2025-02-15', 2, 2, 2),
(60, 2, '2025-02-25 09:30:00', '2025-02-16', 2, 2, 1),
(14, 4, '2025-02-26 08:00:00', '2025-02-17', 2, 2, 2),
(28, 3, '2025-02-26 09:30:00', '2025-02-18', 2, 2, 2),
(11, 2, '2025-02-27 08:00:00', '2025-02-18', 3, 1, 1),
(20, 6, '2025-02-27 09:30:00', '2025-02-20', 2, 2, 1),
(42, 5, '2025-02-28 08:00:00', '2025-02-19', 2, 2, 2),
(53, 6, '2025-02-28 09:30:00', '2025-02-20', 2, 2, 1),
(4, 6, '2025-03-03 08:00:00', '2025-02-18', 2, 2, 2),
(15, 4, '2025-03-03 09:30:00', '2025-02-20', 2, 2, 2),
(22, 2, '2025-03-03 11:00:00', '2025-02-22', 2, 2, 1),
(1, 1, '2025-03-04 08:00:00', '2025-02-21', 2, 2, 2),
(18, 6, '2025-03-04 09:30:00', '2025-02-25', 2, 2, 3),
(27, 3, '2025-03-04 11:00:00', '2025-02-23', 2, 2, 1),
(9, 4, '2025-03-05 08:30:00', '2025-02-22', 2, 2, 2),
(33, 2, '2025-03-05 10:00:00', '2025-02-24', 2, 2, 1),
(52, 1, '2025-03-06 08:00:00', '2025-02-25', 2, 2, 2),
(37, 3, '2025-03-06 09:30:00', '2025-02-26', 2, 2, 2),
(12, 6, '2025-03-07 08:00:00', '2025-02-27', 3, 1, 1),
(45, 5, '2025-03-07 09:30:00', '2025-02-26', 2, 2, 2),
(6, 4, '2025-03-10 08:00:00', '2025-03-01', 2, 2, 2),
(29, 3, '2025-03-10 09:30:00', '2025-02-28', 2, 2, 1),
(51, 6, '2025-03-10 11:00:00', '2025-03-02', 2, 2, 3),
(17, 1, '2025-03-11 08:00:00', '2025-02-28', 2, 2, 2),
(24, 2, '2025-03-11 09:30:00', '2025-03-01', 2, 2, 1),
(30, 4, '2025-03-12 08:00:00', '2025-03-02', 2, 2, 2),
(58, 6, '2025-03-12 09:30:00', '2025-03-04', 2, 2, 3), 
(34, 3, '2025-03-13 08:00:00', '2025-03-02', 2, 2, 2),
(21, 6, '2025-03-13 09:30:00', '2025-03-05', 2, 2, 1),
(2, 2, '2025-03-14 08:00:00', '2025-03-04', 3, 1, 1),
(16, 1, '2025-03-17 08:00:00', '2025-03-07', 2, 2, 2),
(29, 3, '2025-03-17 09:30:00', '2025-03-08', 2, 2, 1),
(54, 6, '2025-03-17 11:00:00', '2025-03-10', 2, 2, 1),
(5, 2, '2025-03-18 08:00:00', '2025-03-07', 2, 2, 2),
(41, 5, '2025-03-18 09:30:00', '2025-03-09', 2, 2, 1),
(10, 4, '2025-03-19 08:00:00', '2025-03-08', 2, 2, 2),
(26, 6, '2025-03-19 09:30:00', '2025-03-10', 2, 2, 1),
(38, 3, '2025-03-20 08:00:00', '2025-03-11', 2, 2, 2),
(47, 6, '2025-03-20 09:30:00', '2025-03-12', 2, 2, 3),
(3, 4, '2025-03-21 08:00:00', '2025-03-12', 2, 2, 2),
(49, 5, '2025-03-21 09:30:00', '2025-03-13', 2, 2, 2),
(7, 6, '2025-03-24 08:00:00', '2025-03-15', 3, 1, 1),
(31, 3, '2025-03-24 09:30:00', '2025-03-16', 2, 2, 2),
(55, 1, '2025-03-25 08:00:00', '2025-03-15', 2, 2, 2),
(60, 2, '2025-03-25 09:30:00', '2025-03-16', 2, 2, 1),
(14, 4, '2025-03-26 08:00:00', '2025-03-17', 2, 2, 2),
(28, 3, '2025-03-26 09:30:00', '2025-03-18', 2, 2, 2),
(11, 2, '2025-03-27 08:00:00', '2025-03-18', 3, 1, 1),
(20, 6, '2025-03-27 09:30:00', '2025-03-20', 2, 2, 1),
(42, 5, '2025-03-28 08:00:00', '2025-03-19', 2, 2, 2),
(53, 6, '2025-03-28 09:30:00', '2025-03-20', 2, 2, 1),
(1, 1, '2026-03-20 10:00:00', '2026-03-06', 1, 1, 1),
(2, 6, '2026-03-20 11:00:00', '2026-03-06', 3, 3, 3);



/*
--------------------------------------------------------------------
DIAGNOZY MEDYCZNE
--------------------------------------------------------------------
Diagnozy przypisane do wizyt zrealizowanych.
--------------------------------------------------------------------
*/

INSERT INTO Diagnoza (WizytaID, ICD10ID, OpisDodatkowy)

SELECT 
    l.WizytaID,
    l.ICD10ID,
    l.Opis
FROM (VALUES
    (1, 1, 'Nadciśnienie tętnicze – pierwsza konsultacja'),
    (6, 2, 'Dławica piersiowa stabilna'),
    (11, 1, 'Nadciśnienie – kontrola'),
    (16, 3, 'Niewydolność serca – modyfikacja leczenia'),
    (21, 1, 'Nadciśnienie pierwotne'),
    (24, 2, 'Dławica wysiłkowa'),
    (30, 3, 'Niewydolność serca – kontrola'),
    (39, 1, 'Nadciśnienie – stabilne wartości'),
    (2, 10, 'Atopowe zapalenie skóry – leczenie miejscowe'),
    (13, 11, 'Łuszczyca zwykła'),
    (17, 10, 'AZS – zaostrzenie'),
    (28, 11,'Łuszczyca – kontrola terapii'),
    (32, 10,'Zmiany alergiczne skóry'),
    (38, 11, 'Łuszczyca – konsultacja'),
    (3, 8, 'Ból grzbietu odcinka lędźwiowego'),
    (10, 9, 'Choroba zwyrodnieniowa kolana'),
    (14, 8, 'Zespół bólowy kręgosłupa'),
    (18, 8, 'Ból grzbietu po przeciążeniu'),
    (22, 9, 'Zmiany zwyrodnieniowe stawu kolanowego'),
    (27, 8, 'Przewlekły ból pleców'),
    (31, 9, 'Gonartroza – kontrola'),
    (36, 8, 'Ból grzbietu – konsultacja'),
    (4, 4, 'Cukrzyca typu 2 – pierwsza wizyta'),
    (9, 5, 'Niedoczynność tarczycy'),
    (15, 4, 'Cukrzyca – kontrola glikemii'),
    (20, 5, 'Niedoczynność tarczycy – korekta dawki'),
    (25, 4, 'Cukrzyca typu 2 – stabilizacja'),
    (33, 5, 'Niedoczynność tarczycy – kontrola'),
    (37, 4, 'Cukrzyca – konsultacja'),
    (1, 7, 'Ostre zapalenie górnych dróg oddechowych – objawy infekcji sezonowej'),
    (3, 46, 'Ostry nieżyt nosa – infekcja wirusowa'),
    (5, 50, 'Porada lekarska – teleporada kontrolna'),
    (12, 47, 'Ostre zapalenie gardła – leczenie objawowe'),
    (22, 48, 'Ostre zapalenie oskrzeli – kaszel i stan podgorączkowy'),
    (24, 19, 'Badanie ogólne – wizyta profilaktyczna'),
    (26, 7,  'Infekcja sezonowa – teleporada'),
    (34, 18, 'Nawracające bóle głowy'),
    (41, 45, 'Pogorszenie pamięci, diagnostyka zaburzeń funkcji poznawczych'),
    (42, 16, 'Migrena przewlekła – wizyta kontrolna, modyfikacja leczenia'),
    (43, 44, 'Drętwienie kończyn dolnych – podejrzenie polineuropatii'),
    (44, 7,  'Infekcja górnych dróg oddechowych – objawy sezonowe'),
    (45, 5,  'Niedoczynność tarczycy – kontrola leczenia'),
    (46, 10, 'Atopowe zapalenie skóry – kontrola'),
    (47, 1,  'Nadciśnienie tętnicze – kontrola'),
    (48, 50, 'Teleporada – infekcja sezonowa'),
    (49, 8,  'Ból grzbietu – przeciążenie'),
    (50, 5,  'Niedoczynność tarczycy – stabilizacja'),
    (51, 11, 'Łuszczyca – kontrola zmian'),
    (52, 1,  'Nadciśnienie – kontrola'),
    (53, 9,  'Choroba zwyrodnieniowa kolana'),
    (55, 16, 'Migrena – konsultacja neurologiczna'),
    (56, 4,  'Cukrzyca typu 2 – kontrola glikemii'),
    (57, 8,  'Przewlekły ból pleców'),
    (58, 50, 'Teleporada – konsultacja rodzinnego'),
    (59, 22, 'Przewlekła choroba niedokrwienna serca'),
    (60, 10, 'AZS – zaostrzenie zmian'),
    (61, 4,  'Cukrzyca typu 2 – modyfikacja leczenia'),
    (62, 50, 'Teleporada – kontrola wyników'),
    (63, 31, 'Choroba zwyrodnieniowa biodra'),
    (64, 46, 'Ostry nieżyt nosa'),
    (66, 1,  'Nadciśnienie – kontrola'),
    (67, 34, 'Skręcenie kolana – kontrola'),
    (68, 7,  'Infekcja sezonowa – konsultacja'),
    (69, 40, 'Zaburzenia przysadki mózgowej'),
    (70, 42, 'Zespół bólu głowy'),
    (71, 36, 'Nadczynność tarczycy'),
    (72, 7,  'Infekcja górnych dróg oddechowych'),
    (73, 8,  'Ból kręgosłupa lędźwiowego'),
    (74, 50, 'Teleporada – kontrola leczenia'),
    (75, 4,  'Cukrzyca typu 2 – kontrola'),
    (76, 44, 'Polineuropatia'),
    (78, 32, 'Dyskopatia lędźwiowa'),
    (79, 21, 'Choroba nadciśnieniowa z zajęciem serca'),
    (80, 26, 'Zapalenie skóry nieokreślone'),
    (81, 5,  'Niedoczynność tarczycy – kontrola'),
    (82, 17, 'Zaburzenia refrakcji'),
    (84, 7,  'Infekcja sezonowa – konsultacja'),
    (85, 43, 'Zespół cieśni nadgarstka'),
    (86, 50, 'Teleporada – porada lekarska')
) AS l(WizytaID, ICD10ID, Opis)

JOIN Wizyta v 
    ON v.WizytaID = l.WizytaID

JOIN LekarzSpecjalizacja ls
    ON ls.LekarzID = v.LekarzID

JOIN SpecjalizacjaICD10 s
    ON s.SpecjalizacjaID = ls.SpecjalizacjaID
   AND s.ICD10ID = l.ICD10ID

WHERE v.StatusWizytyID = 2;



/*
--------------------------------------------------------------------
PŁATNOŚCI
--------------------------------------------------------------------
Rejestr płatności powiązanych z wizytami.
Kwoty zgodne z tabelą Cennik.
--------------------------------------------------------------------
*/

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
LEFT JOIN Platnosc p ON p.WizytaID = w.WizytaID
WHERE w.WizytaID BETWEEN 1 AND 132 
  AND w.StatusWizytyID = 2
  AND p.WizytaID IS NULL;