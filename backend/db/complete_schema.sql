-- complete_schema.sql

-- 1. USERS TABLE

CREATE TABLE users ( -- se creeaza o tabela noua numita users
    -- campuri de identificare
    id SERIAL PRIMARY KEY, -- camp de identificare unica, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare user, nu pot fi doi cu acelasi id
    name VARCHAR(100) NOT NULL, -- camp pentru numele complet al utilizatorului de tip text de maxim 100 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- campuri pentru login
    email VARCHAR(255) NOT NULL UNIQUE, -- camp pentru email de tip text de maxim 255 de caractere, NOT NULL pentru ca trebuie obligatoriu completat si UNIQUE pentru ca nu pot exista 2 useri cu acelasi email
    password VARCHAR(255) NOT NULL, -- camp pentru parola de tip text de maxim 255 de caractere, NOT NULL pentru ca trebuie obligatoriu completata, va fi hashed cu bcrypt inainte de stocare, nu se va stoca in clar
    
    -- avatarul utilizatorului
    avatar BYTEA, -- imaginea avatar stocata ca date binare (BYTEA = Binary Data), permite stocarea directa a imaginii in baza de date
    avatar_url VARCHAR(255), -- link alternativ catre imagine, in caz ca binar nu functioneaza, de tip text de maxim 255 de caractere, util pentru imagini hostate extern
    
    -- verificari 
    is_verified BOOLEAN DEFAULT false, -- camp de tip boolean care retine daca utilizatorul si-a verificat adresa de email sau nu, DEFAULT false, deci la crearea contului e automat false pana la verificare 
    is_admin BOOLEAN DEFAULT false, -- camp de tip boolean care retine daca utilizatorul are drept de administrator, DEFAULT false, pentru ca majoritatea utilizatorilor sunt obisnuiti, nu admini
    
    -- forgot password
    reset_password_token VARCHAR(255), -- camp folosit pentru functia de forgot password, token-ul fiind un cod secret pentru resetare, de tip text de maxim 255 de caractere
    reset_password_expires_at TIMESTAMP, -- camp care retine cand expira token-ul folosit la recuperarea parolei, de tip data si ora
    
    -- verificare email
    verification_token VARCHAR(255), -- camp folosit pentru verificarea email-ului, stocheaza token-ul trimis pe mail, de tip text de 255 de caractere
    verification_token_expires_at TIMESTAMP, -- camp care retine cand expira token-ul folosit la verificarea email-ului, de tip data si ora
    
    -- timestamps 
    last_login TIMESTAMP, -- camp de tip data si ora care retine ultima conectare a utilizatorului, util pentru statistici si securitate
    deleted_at TIMESTAMP DEFAULT NULL, -- camp pentru soft delete (stergere logica, nu fizica), pentru conformitate GDPR, DEFAULT NULL inseamna user activ, daca are o data inseamna user sters, deci conform GDPR se pastreaza un istoric dar marcat ca sters
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost creat contul, CURRENT_TIMESTAMP retine exact momentul in care a fost creat
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost actualizat contul, CURRENT_TIMESTAMP retine exact momentul in care a fost actualizat, se actualizeaza automat prin trigger la orice modificare
);

-- 2. PETS TABLE

CREATE TABLE pets ( -- se creeaza o tabela noua numita pets
    -- campuri de identificare
    id SERIAL PRIMARY KEY, -- camp de identificare, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare animal, nu pot fi doua animale cu acelasi id
    name VARCHAR(100) NOT NULL, -- camp pentru nume de tip text de maxim 100 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- caracteristici
    type VARCHAR(50) NOT NULL, -- camp pentru tipul animalului (dog, cat, bird, rabbit, other), de tip text de maxim 50 de caractere, NOT NULL pentru ca trebuie obligatoriu completat, utilizat pentru filtrare si cautare
    breed VARCHAR(100), -- camp pentru rasa de tip text de maxim 100 de caractere, poate fi NULL pentru animalele de rasa necunoscuta sau amestec
    age_category VARCHAR(20), -- camp pentru categorie de varsta (puppy, young, adult, senior), de tip text de maxim 20 de caractere, folosit pentru filtrare
    gender VARCHAR(20), -- camp pentru gen (male, female, unknown), de tip text de maxim 20 de caractere
    size VARCHAR(20), -- camp pentru dimensiune (small, medium, large), de tip text de maxim 20 de caractere
    color VARCHAR(50), -- camp pentru culoare de tip text de maxim 50 de caractere
    coat VARCHAR(50), -- camp pentru blana (short, long, medium), de tip text de maxim 50 de caractere
    fee DECIMAL(10, 2) DEFAULT 0, -- camp pentru taxa, de tip numar cu virgula, DECIMAL(10, 2) pentru ca poate avea 10 cifre in total, 2 cifre dupa virgula, DEFAULT 0 deci daca nu se specifica, adoptia e gratuita
    description TEXT, -- camp pentru descriere de tip text nelimitat
    health_status TEXT, -- camp pentru starea de sanatate de tip text nelimitat, include vaccinuri, sterilizare, probleme medicale cunoscute
    story TEXT, -- camp pentru povestea animalului de tip text nelimitat
    
    -- features detectate de AI
    ai_breed_detected VARCHAR(100), -- camp pentru rasa detectata de tip text de maxim 100 de caractere
    ai_color_detected VARCHAR(50), -- camp pentru culoarea detectata, de tip text de maxim 50 de caractere
    ai_size_detected VARCHAR(20), -- camp pentru marimea detectata, de tip text de maxim 20 de caractere
    ai_age_detected VARCHAR(20), -- camp pentru varsta detectata, de tip text de maxim 20 de caractere
    ai_confidence DECIMAL(5, 2), -- scorul de incredere, de la 0 la 100, sub forma DECIMAL(5, 2) pentru ca poate avea maxim 5 cifre, 2 dupa virgula
    ai_analyzed_at TIMESTAMP, -- camp care retine cand a fost analizata imaginea de tip TIMESTAMP
    
    -- locatie
    location_address VARCHAR(255), -- camp pentru adresa, de tip text de maxim 255 de caractere
    location_city VARCHAR(100), --  camp pentru oras, de tip text de maxim 100 de caractere
    location_country VARCHAR(100), -- camp pentru tara, de tip text de maxim 100 de caractere
    zip_code VARCHAR(20), -- camp pentru cod postal, de tip text de maxim 20 de caractere
    
    -- contact
    shelter_contact_email VARCHAR(255), -- camp pentru adresa de email a shelter-ului, de tip text de maxim 255 de caractere
    shelter_contact_phone VARCHAR(50), -- camp pentru numarul de telefon al shelter-ului, de tip text de maxim 50 de caractere
    
    -- status
    is_available BOOLEAN DEFAULT true, -- camp care retine daca animalul mai e disponibil, de tip BOOLEAN, setat DEFAULT true
    adoption_status VARCHAR(20) DEFAULT 'available', -- camp pentru statusul de adoptie (available, pending, in_review, adopted), de tip text de maxim 20 de caractere
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost creat profilul animalului, CURRENT_TIMESTAMP retine exact momentul in care a fost creat
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost actualizat profilul animalului, CURRENT_TIMESTAMP retine exact momentul in care a fost actualizat
);

-- 3. PET PHOTOS TABLE

CREATE TABLE pet_photos ( -- se creeaza o tabela noua numita pet_photos, relatie one-to-many, un animal poate avea poze multiple
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare al imaginii, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare poza, nu pot fi doua poze cu acelasi id
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul animalului din tabela pets, este de tip intreg, NOT NULL pentru ca trebuie obligatoriu completat, REFERENCES pets(id) pentru ca trebuie sa existe in tabela pets, ON DELETE CASCADE inseamna ca daca sterg un pet, se sterg automat si pozele
    
    -- campuri legate de poze
    photo_data BYTEA, -- imagine stocata sub forma de date binare (BYTEA), permite stocarea directa in baza de date, avantaj - toate datele intr-un singur loc, dezavantaj - mareste dimensiunea DB
    photo_name VARCHAR(255), -- camp pentru denumirea imaginii, de ip text de maxim 255 de caractere
    content_type VARCHAR(100), -- camp pentru tipul imaginii, (MIME type (image/jpeg, image/png)), de tip text de maxim 100 de caractere
    photo_url VARCHAR(255), -- link alternativ catre imagine, in caz ca binar nu functioneaza, de tip text de maxim 255 de caractere
    is_primary BOOLEAN DEFAULT false, -- camp care verifica daca imaginea in cauza este prima poza, cea principala, de tip BOOLEAN, DEFAULT false
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost creata imaginea, CURRENT_TIMESTAMP retine exact momentul in care a fost creata
);

-- 4. PET TRAITS TABLE
-- este o tabela separata pentru a putea face cautari mai eficiente, mult mai rapid decat cautarea in string-uri concatenate
CREATE TABLE pet_traits ( -- se creeaza o tabela noua numita pet_traits, relatie many-to-many, un animal poate avea mai multe caracteristici, o caracteristica poate fi specifica mai multor animale
    --  campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare al caracteristicii animalului, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare trait, nu pot fi doua caracteristici cu acelasi id
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul animalului din tabela pets, este de tip intreg, NOT NULL pentru ca trebuie obligatoriu completat, REFERENCES pets(id) pentru ca trebuie sa existe in tabela pets, ON DELETE CASCADE inseamna ca daca sterg un pet, se sterg automat si caracteristicile
    
    -- camp pentru caracteristica
    trait VARCHAR(100) NOT NULL, -- camp pentru caracteristica (friendly, energetic, calm, good_with_kids, etc.), de tip text de maxim 100 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost creata caracteristica, CURRENT_TIMESTAMP retine exact momentul in care a fost creata
);

-- 5. ADOPTIONS TABLE 

CREATE TABLE adoptions ( -- se creeaza o tabela noua numita adoptions
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare al adoptiei, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare adoptie, nu pot fi doua adoptii cu acelasi id
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- foreign key, face legatura cu userul care adopta, INTEGER pentru ca id-ul este de tip intreg, REFERENCES users(id), pentru ca trebuie sa existe in tabela users, ON DELETE SET NULL - daca userul isi sterge contul (GDPR), user_id devine NULL dar cererea ramane in sistem pentru istoric, spre deosebire de cascade care ar sterge tot
    pet_id INTEGER NOT NULL, -- id-ul animalului (nu e foreign key cu references), NOT NULL pentru ca trebuie obligatoriu completat, pastrat ca nr simplu pentru a mentine istoric chiar daca animalul este sters din sistem dupa adoptie, denormalizare intentionata pentru historical records
    
    -- informatii despre animalul adoptat (denormalizate pentru historical records)
    -- se duplica datele animalului pentru a pastra un istoric permanent
    pet_name VARCHAR(100) NOT NULL, -- camp care retine numele animalului, de tip text de maxim 100 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    pet_type VARCHAR(50) NOT NULL, -- camp care retine tipul animalului, de tip text de maxim 50 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    pet_breed VARCHAR(100), -- camp care retine rasa animalului, de tip text de maxim 100 de caractere
    
    -- statusul adoptiei
    status VARCHAR(20) DEFAULT 'pending', -- camp pentru statusul adoptiei (pending, in_review, approved, rejected), de tip text de maxim 20 de caractere
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost facuta cererea de adoptie, CURRENT_TIMESTAMP retine exact momentul in care a fost facuta
    
    -- informatii personale despre cel care adopta (din formular)
    full_name VARCHAR(100), -- camp pentru numele complet, de tip text de maxim 100 de caractere
    email VARCHAR(255), -- camp pentru email, de tip text de maxim 255 de caractere
    phone VARCHAR(50), -- camp pentru numarul de telefon, de tip text de maxim 50 de caractere
    address VARCHAR(255), -- camp pentru adresa, de tip text de maxim 255 de caractere
    city VARCHAR(100), -- camp pentru oras, de tip text de maxim 100 de caractere
    postal_code VARCHAR(20), -- camp pentru codul postal, de tip text de maxim 20 de caractere
    
    -- informatii despre situatia locuintei
    housing_type VARCHAR(50), -- camp pentru tipul de locuinta (house, apartment, condo, etc.), de tip text de maxim 50 de caractere
    living_arrangement VARCHAR(100), -- camp pentru situatie, de tip text de 100 de caractere
    has_yard VARCHAR(20), -- camp pentru existenta unei curti (yes, no, shared), de tip text de maxim 20 de caractere
    
    -- informatii despre familie
    has_children BOOLEAN, -- camp care retine daca exista sau nu copii, de tip BOOLEAN
    children VARCHAR(100), -- camp care retine detalii despre copii, de tip text de 100 de caractere
    
    -- informatii despre experienta cu animalele
    has_other_pets BOOLEAN, -- camp care retine daca exista si alte animale, de tip BOOLEAN
    other_pets VARCHAR(100), -- camp cu lista animalelor actuale, de tip text de maxim 100 de caractere
    other_pets_details TEXT, -- camp cu detalii despre celelalte animale daca exista, de tip text nelimitat
    previous_pet_experience TEXT, -- camp care retine informatii despre experienta anterioara cu animale de companie, de tip text nelimitat
    
    -- detalii despre cererea de adoptie
    adoption_reason TEXT, -- camp cu motivul pentru care doreste sa adopte, de tip text nelimitat
    message TEXT, -- camp cu mesaje suplimentare catre adapost, de tip text nelimitat
    notes TEXT, -- camp cu notite ale utilizatorului, de tip text nelimitat
    admin_notes TEXT, -- camp cu notite ale administratorului, de tip text nelimitat
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost creata cererea, automat la inserare
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost actualizata cererea, se modifica automat prin trigger
);

-- 6. DONATIONS TABLE 

CREATE TABLE donations ( -- se creeaza o tabela noua numita donations, pentru gestionarea donatiilor monetare catre adapost
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare unica a donatiei, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare donatie, nu pot fi doua donatii cu acelasi id
    user_id INTEGER REFERENCES users(id) ON DELETE NULL, -- -- foreign key, face legatura cu userul care doneaza, INTEGER pentru ca id-ul este de tip intreg, REFERENCES users(id), pentru ca trebuie sa existe in tabela users, ON DELETE SET NULL - daca userul isi sterge contul (GDPR), user_id devine NULL dar cererea ramane in sistem pentru istoric, spre deosebire de cascade care ar sterge tot
    email VARCHAR(255) NOT NULL, -- camp pentru email, de tip text de maxim 255 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- campuri pentru valoarea tranzactiei
    amount DECIMAL(10, 2) NOT NULL, -- camp pentru suma donata, de tip numar cu virgula, DECIMAL(10, 2) pentru ca poate avea 10 cifre in total, 2 cifre dupa virgula, NOT NULL pentru ca trebuie obligatoriu completat
    currency VARCHAR(3) DEFAULT 'eur', -- camp pentru valuta in care se efectueaza donatia, de tip text de maxim 3 caractere, DEFAULT eur pentru ca implicit donatiile se fac in euro
    
    -- detalii plata stripe
    stripe_session_id VARCHAR(255), -- camp care retine id-ul sesiunii stripe pentru checkout, de tip text de maxim 255 de caractere, stocat pentru a putea verifica statusul platii sau pentru a face refund
    payment_intent_id VARCHAR(255), -- camp care retine id-ul intent-ului de plata stripe (confirmare finala), de tip text de maxim 255 de caractere
    
    -- status plata
    status VARCHAR(20) DEFAULT 'pending', -- camp care retine statusul donatiei (pending, completed, canceled, failed), DEFAULT pendinf pentru ca șa creare e in asteptare pana confirma stripe
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost initiata donatia, CURRENT_TIMESTAMP pentru ca se retine exact in momentul efectuarii
);

-- 7. MESSAGES TABLE 

CREATE TABLE messages ( -- se creeaza o tabela noua numita messages
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare unica a mesajului, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare mesaj, nu pot fi doua mesaje cu acelasi id
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul mesagerului din tabela users, este de tip intreg, NOT NULL pentru ca trebuie obligatoriu completat, REFERENCES users(id) pentru ca trebuie sa existe in tabela users, ON DELETE CASCADE inseamna ca daca sterg un user, se sterg automat si mesajele
    name VARCHAR(100) DEFAULT '', -- camp pentru numele complet al utilizatorului de tip text de maxim 100 de caractere, DEFAULT '' reprezentand un string gol daca nu este completat, pentru vizitatorii anonimi
    email VARCHAR(255) NOT NULL, -- camp pentru email, de tip text de maxim 255 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- campuri legate de mesaj 
    message TEXT NOT NULL CHECK (char_length(message) <= 1800), -- camp pentru mesaj, de tip text teoretic nelimitat, dar verificarea din paranteza este un constraint de maxim 1800 de caractere, o limita impusa pentru a evita spam
    read BOOLEAN DEFAULT false, -- camp care marcheaza daca mesajul a fost citit de admin, de tip BOOLEAN, DEFAULT false pentru ca la primire e automat necitit, devine true cand adminul il deschide
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost trimis mesajul, automat la inserare
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine momentul ultimei actualizari (marcare ca citit), se modifica automat prin trigger
);

-- 8. SCHEDULED MEETINGS TABLE 

CREATE TABLE scheduled_meetings ( -- se creeaza o tabela noua numita scheduled meetings
    -- campuri pentru identificare 
    id SERIAL PRIMARY KEY, -- camp de identificare unica a meeting-ului, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare meeting, nu pot fi doua meetings cu acelasi id
    adoption_id INTEGER NOT NULL REFERENCES adoptions(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul cererii de adoptie din tabela adoptions, este de tip intreg, NOT NULL pentru ca trebuie obligatoriu completat, REFERENCES adoptions(id) pentru ca trebuie sa existe in tabela adoptions, ON DELETE CASCADE inseamna ca daca sterg o cerere, se sterge automat si meeting-ul
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul adoptatorului din tabela users, este de tip intreg, NOT NULL pentru ca trebuie obligatoriu completat, REFERENCES users(id) pentru ca trebuie sa existe in tabela users, ON DELETE CASCADE inseamna ca daca sterg un user, se sterge automat si meeting-ul
    pet_id INTEGER NOT NULL, -- camp de identificare unica a animalului (nu e foreign key), NOT NULL pentru ca trebuie obligatoriu completat, necesar pentru a pastra un istoric chiar daca animalul e sters
    pet_name VARCHAR(100) NOT NULL, -- camp care retine numele animalului (denormalizare pentru istoric), de tip text de maxim 100 de caractere, NOT NULL pentru ca trebuie obligatoriu completat
    
    -- detalii despre meeting
    scheduled_date DATE NOT NULL, -- camp care retine data intalnirii si doar aceasta, NOT NULL pentru ca trebuie obligatoriu completat
    scheduled_time VARCHAR(20) NOT NULL, -- camp care retine ora intalnirii ca string, de tip text de maxim 20 de caractere, NOT NULL pentru ca trebuie obligatoriu completat, e string pentru flexibilitate (permite scrierea unor cuvinte precum dimineata, la prima ora, seara)
    location VARCHAR(255) NOT NULL, -- camp care retine locatia intalnirii, de tip text de maxim 255 decaractere, NOT NULL pentru ca trebuie obligatoriu completat
    notes TEXT, -- camp care retine notite aditionale legate de intalnire, de tip text nelimitat
    
    -- status si raspuns
    status VARCHAR(20) DEFAULT 'pending', -- camp care retine statusul intalnirii (pending, accepted, rejected), de tip text de maxim 20 de caractere, DEFAULT pending pentru ca la creare e in asteptare
    response_date TIMESTAMP, -- camp de tip data si ora care retine cand a fost acceptata sau respinsa propunerea de scheduled meeting, NULL pana cand adminul raspunde
    admin_message TEXT, -- camp care retine un mesaj de la administrator la utilizator, de tip text nelimitat
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost creata cererea de intalnire, automat la inserare
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- camp de tip data si ora care retine cand a fost realizata ultima actualizare, se modifica automat prin trigger
);

-- 9. FAVORITES TABLE
  CREATE TABLE favorites ( -- se creeaza o tabela noua numita favorites
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare unica a favoritului, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare favorit, nu pot fi doua favorite cu acelasi id
    user_id INTEGER REFERENCES users(id), -- foreign key, reprezinta id-ul utilizatorului din tabela users, este de tip intreg, REFERENCES users(id) pentru ca trebuie sa existe in tabela users, ON DELETE CASCADE inseamna ca daca sterg un user, se sterg automat si favoritele lui
    pet_id INTEGER REFERENCES pets(id), -- foreign key, reprezinta id-ul animalului din tabela pets, este de tip intreg, REFERENCES pets(id) pentru ca trebuie sa existe in tabela pets, ON DELETE CASCADE inseamna ca daca sterg un animal, se sterge automat si din listele de favorite

    -- timestamps
    created_at TIMESTAMP DEFAULT NOW(), -- camp de tip data si ora care retine cand a fost adaugat animalul la favorite, CURRENT_TIMESTAMP retine exact momentul in care a fost adaugat, util pentru sortare cronologica

    -- constrangere de unicitate
    UNIQUE(user_id, pet_id) -- constrangere care asigura ca un utilizator nu poate adauga acelasi animal de mai multe ori la favorite, combinatia user_id + pet_id trebuie sa fie unica in tabela
  );

-- 10. USER SWIPES TABLE

  CREATE TABLE user_swipes ( -- se creeaza o tabela noua numita user_swipes, pentru gestionarea interactiunilor tip Tinder (swipe left/right) ale utilizatorilor cu animalele
    -- campuri pentru identificare
    id SERIAL PRIMARY KEY, -- camp de identificare unica a swipe-ului, serial pentru ca e un nr care creste automat si primary key pentru ca e unic pentru fiecare swipe, nu pot fi doua swipe-uri cu acelasi id
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul utilizatorului din tabela users, este de tip intreg, REFERENCES users(id) pentru ca trebuie sa existe in tabela users, ON DELETE CASCADE inseamna ca daca sterg un user, se sterg automat si swipe-urile lui
    pet_id INTEGER REFERENCES pets(id) ON DELETE CASCADE, -- foreign key, reprezinta id-ul animalului din tabela pets, este de tip intreg, REFERENCES pets(id) pentru ca trebuie sa existe in tabela pets, ON DELETE CASCADE inseamna ca daca sterg un animal, se sterge automat si din istoricul de swipe-uri
    
    -- actiunea utilizatorului
    action VARCHAR(10) NOT NULL, -- camp pentru tipul actiunii ('like' sau 'pass'), de tip text de maxim 10 caractere, NOT NULL pentru ca trebuie obligatoriu completat, 'like' inseamna swipe right (interesat), 'pass' inseamna swipe left (nu e interesat)
    
    -- timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- camp de tip data si ora care retine cand a fost efectuat swipe-ul, CURRENT_TIMESTAMP retine exact momentul in care a fost efectuat, util pentru statistici si pentru a nu arata din nou acelasi animal userului
    
    -- constrangere de unicitate
    UNIQUE(user_id, pet_id) -- constrangere care asigura ca un utilizator nu poate da swipe de mai multe ori la acelasi animal, combinatia user_id + pet_id trebuie sa fie unica in tabela, astfel animalul nu va mai aparea in feed dupa ce utilizatorul a actionat asupra lui
);

-- 11. INDEXES FOR PERFORMANCE
-- indexes sunt structuri de date suplimentare care permit cautari rapide
-- fara index postgreSQL scaneaza toate randurile, deci este lent pentru tabele mari
-- cu index postgreSQL foloseste o structura sortata pentru gasire instantanee

-- index pentru users
CREATE INDEX idx_users_email ON users(email); -- index pe email pentru cautari rapide la login si verificare unicitate - WHERE email = '...'
CREATE INDEX idx_users_verified ON users(is_verified); -- index pe is_verified pentru filtrare useri verificati - WHERE is_verified = true
CREATE INDEX idx_users_admin ON users(is_admin); -- index pe is_admin pentru gasirea rapida a adminilor - WHERE is_admin = true
CREATE INDEX idx_users_deleted ON users(deleted_at); -- index pe deleted_at pentru excluderea userilor stersi - WHERE deleted_at IS NULL = useri activi

-- index pentru pets
CREATE INDEX idx_pets_type ON pets(type); -- index pe tipul animalului pentru filtrare dupa tip, folosit frecvent in search - WHERE type = '...'
CREATE INDEX idx_pets_available ON pets(is_available); -- index pe is_available pentru afisarea doar a animalelor disponibile - WHERE is_available = true
CREATE INDEX idx_pets_status ON pets(adoption_status); -- index pe adoption_status pentru filtrare dupa status - WHERE adoption_status = '...'
CREATE INDEX idx_pets_location ON pets(location_city); -- index pe location_city pentru cautare dupa oras - WHERE location_city = '...'
CREATE INDEX idx_pets_zip ON pets(zip_code); -- index pe zip_code pentru cautare dupa cod postal / raza geografica - WHERE zip_code = '...'
CREATE INDEX idx_pets_size ON pets(size); -- index pe size pentru filtrare in functie de marime - WHERE size = '...'
CREATE INDEX idx_pets_age ON pets(age_category); -- index pe age_category pentru filtrare dupa varsta - WHERE age_category = '...'
CREATE INDEX idx_pets_breed ON pets(breed); -- index pe breed pentru cautare dupa rasa - WHERE breed LIKE '%...%'
CREATE INDEX idx_pets_gender ON pets(gender); -- index pe gender pentru filtrare dupa gen - WHERE gender = '...'
CREATE INDEX idx_pets_color ON pets(color); -- index pe color pentru filtrare dupa culoare - WHERE color LIKE '%...%'

-- index pentru imaginile animalelor
CREATE INDEX idx_pet_photos_pet_id ON pet_photos(pet_id); -- index pe pet_id pentru gasire rapida a tuturor pozelor unui animal - WHERE pet_id = ...
CREATE INDEX idx_pet_photos_primary ON pet_photos(is_primary); -- index pe is_primary pentru gasire rapida a pozei principale - WHERE is_primary = true

-- index pentru caracteristicile animalelor
CREATE INDEX idx_pet_traits_pet_id ON pet_traits(pet_id); -- index pe pet_id pentru gasire rapida a tuturor caracteristicilor unui animal - WHERE pet_id = ...

-- index pentru adoptii
CREATE INDEX idx_adoptions_user_id ON adoptions(user_id); -- index pe user_id pentru gasire rapida a tuturor cererilor unui utilizator - WHERE user_id = ...
CREATE INDEX idx_adoptions_pet_id ON adoptions(pet_id); -- index pe pet_id pentru gasire rapida a tuturor cererilor pentru un animal - WHERE pet_id = ...
CREATE INDEX idx_adoptions_status ON adoptions(status); -- index pe status pentru filtrare dupa status, folosita in panoul admin - WHERE status = '...'
CREATE INDEX idx_adoptions_email ON adoptions(email); -- index pe email pentru cautare dupa email al unui utilizator - WHERE email = '...'

-- index pentru donatii
CREATE INDEX idx_donations_user_id ON donations(user_id); -- index pe user_id pentru istoricul donatiilor unui utilizator - WHERE user_id = ...
CREATE INDEX idx_donations_status ON donations(status); -- index pe status pentru filtrare donatii finalizate - WHERE status = '...'
CREATE INDEX idx_donations_session ON donations(stripe_session_id); -- index pe stripe_session_id pentru verificare rapida a statusului stripe - WHERE stripe_session_id = '...'

-- index pentru mesaje
CREATE INDEX idx_messages_user_id ON messages(user_id); -- index pe user_id pentru istoricul mesajelor cu un anumit utilizator - WHERE user_id = ...
CREATE INDEX idx_messages_email ON messages(email); -- index pe email pentru cautarea mesajelor unui utilizator dupa mail - WHERE email = '...'
CREATE INDEX idx_messages_read ON messages(read); -- index pe read pentru filtrarea mesajelor necitite - WHERE read = false

-- index pentru meetings
CREATE INDEX idx_meetings_user_id ON scheduled_meetings(user_id); -- index pe user_id pentru filtrarea intalnirilor cu un anumit utilizator - WHERE user_id = ...
CREATE INDEX idx_meetings_pet_id ON scheduled_meetings(pet_id); -- index pe pet_id pentru filtrarea intalnirilor pentru un anumit animal - WHERE pet_id = ...
CREATE INDEX idx_meetings_adoption_id ON scheduled_meetings(adoption_id); -- index pe adoption_id pentru cand navigam de la o cerere de adoptie la o anumita intalnire, WHERE adoption_id = ...
CREATE INDEX idx_meetings_date ON scheduled_meetings(scheduled_date); -- index pe scheduled_date pentru a filtra inatlnirile cronologic - WHERE scheduled_date >= CURRENT_DATE ORDER BY scheduled_date
CREATE INDEX idx_meetings_status ON scheduled_meetings(status); -- index pe status pentru filtrarea intalnirilor dupa stare - WHERE status = '...'

-- index pentru user_swipes
CREATE INDEX idx_user_swipes_user_id ON user_swipes(user_id); -- index pe user_id pentru gasire rapida a tuturor swipe-urilor unui utilizator - WHERE user_id = ...
CREATE INDEX idx_user_swipes_pet_id ON user_swipes(pet_id); -- index pe pet_id pentru a vedea cati utilizatori au dat like/pass unui anumit animal - WHERE pet_id = ...
CREATE INDEX idx_user_swipes_action ON user_swipes(action); -- index pe action pentru filtrarea dupa tipul de actiune, util pentru statistici - WHERE action = 'like'
CREATE INDEX idx_user_swipes_user_action ON user_swipes(user_id, action); -- index compus pentru gasire rapida a tuturor like-urilor unui utilizator - WHERE user_id = ... AND action = 'like'

-- 12. TRIGGERS

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pets_updated_at
    BEFORE UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_adoptions_updated_at
    BEFORE UPDATE ON adoptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meetings_updated_at
    BEFORE UPDATE ON scheduled_meetings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-update pet availability based on adoption_status
CREATE OR REPLACE FUNCTION update_pet_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.adoption_status = 'available' THEN
        NEW.is_available := TRUE;
    ELSE
        NEW.is_available := FALSE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_pet_availability
    BEFORE INSERT OR UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_pet_availability();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE users IS 'User accounts - both adopters and admins';
COMMENT ON TABLE pets IS 'Animals available for adoption';
COMMENT ON TABLE pet_photos IS 'Multiple photos per pet, stored as binary data';
COMMENT ON TABLE pet_traits IS 'Behavioral traits and characteristics';
COMMENT ON TABLE adoptions IS 'Adoption applications with extended form data';
COMMENT ON TABLE donations IS 'Monetary donations via Stripe';
COMMENT ON TABLE messages IS 'Simple contact messages from users to shelter';
COMMENT ON TABLE scheduled_meetings IS 'Meeting requests linked to adoption applications';
COMMENT ON TABLE user_swipes IS 'Tinder-style swipe interactions - tracks likes and passes to prevent showing same pets again';

COMMENT ON COLUMN pets.ai_breed_detected IS 'Breed detected by CLIP AI model';
COMMENT ON COLUMN pets.ai_confidence IS 'AI detection confidence score (0-100)';
COMMENT ON COLUMN users.password IS 'Bcrypt hashed password - never store plain text';
COMMENT ON COLUMN adoptions.status IS 'pending, in_review, approved, rejected';
COMMENT ON COLUMN donations.status IS 'pending, completed, canceled, failed';
COMMENT ON COLUMN scheduled_meetings.status IS 'pending, accepted, rejected';
COMMENT ON COLUMN messages.message IS 'Limited to 1800 characters';
COMMENT ON COLUMN user_swipes.action IS 'like (swipe right - interested) or pass (swipe left - not interested)';

-- =====================================================
-- INITIAL ADMIN USER (Optional - for testing)
-- =====================================================

-- Password is 'admin123' hashed with bcrypt
-- In production, create admin through API with proper password
INSERT INTO users (email, password, name, is_admin, is_verified) 
VALUES (
    'admin@shelter.com',
    '$2a$10$rRQGeYWFIYHEvF0P.pZlpOXs5DbZNO7kqPaOtLVBCdXqyV3hqNFOy',
    'Admin User',
    true,
    true
);