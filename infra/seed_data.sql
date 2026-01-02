-- Seed script for TaskMate database
-- Creates 20 users (mix of clients and helpers) with realistic tasks in various states

-- Clear existing data using TRUNCATE CASCADE to handle foreign keys
TRUNCATE TABLE task_messages CASCADE;
TRUNCATE TABLE task_threads CASCADE;
TRUNCATE TABLE task_proofs CASCADE;
TRUNCATE TABLE reviews CASCADE;
TRUNCATE TABLE payments CASCADE;
TRUNCATE TABLE task_assignments CASCADE;
TRUNCATE TABLE task_offers CASCADE;
TRUNCATE TABLE messages CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE addresses CASCADE;
TRUNCATE TABLE payment_methods CASCADE;
TRUNCATE TABLE user_documents CASCADE;
TRUNCATE TABLE users CASCADE;

-- Reset sequences
ALTER SEQUENCE users_id_seq RESTART WITH 1;
ALTER SEQUENCE tasks_id_seq RESTART WITH 1;
ALTER SEQUENCE task_offers_id_seq RESTART WITH 1;
ALTER SEQUENCE task_assignments_id_seq RESTART WITH 1;
ALTER SEQUENCE task_threads_id_seq RESTART WITH 1;
ALTER SEQUENCE task_messages_id_seq RESTART WITH 1;
ALTER SEQUENCE task_offers_id_seq RESTART WITH 1;
ALTER SEQUENCE task_assignments_id_seq RESTART WITH 1;
ALTER SEQUENCE task_threads_id_seq RESTART WITH 1;
ALTER SEQUENCE task_messages_id_seq RESTART WITH 1;

-- ============================================
-- USERS (20 users: 12 clients, 8 helpers)
-- Password for all: "password123" (bcrypt hash)
-- ============================================

INSERT INTO users (id, email, hashed_password, role, name, phone, bio, hourly_rate, is_available, skills, document_status, preferences, readiness_status) VALUES
-- Clients (IDs 1-12)
(1, 'mario.rossi@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Mario Rossi', '+39 333 1234567', 'Professionista IT, sempre alla ricerca di aiuto per lavori domestici', NULL, false, '[]', 'unverified', '{}', '{}'),
(2, 'giulia.bianchi@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Giulia Bianchi', '+39 340 2345678', 'Mamma lavoratrice, ho bisogno di aiuto con le pulizie', NULL, false, '[]', 'unverified', '{}', '{}'),
(3, 'luca.ferrari@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Luca Ferrari', '+39 338 3456789', 'Studente universitario fuori sede', NULL, false, '[]', 'unverified', '{}', '{}'),
(4, 'anna.conti@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Anna Conti', '+39 347 4567890', 'Pensionata, vivo sola e ho bisogno di aiuto occasionale', NULL, false, '[]', 'unverified', '{}', '{}'),
(5, 'paolo.romano@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Paolo Romano', '+39 339 5678901', 'Imprenditore, poco tempo per i lavori di casa', NULL, false, '[]', 'unverified', '{}', '{}'),
(6, 'francesca.moretti@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Francesca Moretti', '+39 335 6789012', 'Avvocato, sempre impegnata in ufficio', NULL, false, '[]', 'unverified', '{}', '{}'),
(7, 'alessandro.colombo@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Alessandro Colombo', '+39 342 7890123', 'Medico, orari impossibili', NULL, false, '[]', 'unverified', '{}', '{}'),
(8, 'elena.ricci@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Elena Ricci', '+39 348 8901234', 'Freelancer, lavoro da casa', NULL, false, '[]', 'unverified', '{}', '{}'),
(9, 'giorgio.marini@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Giorgio Marini', '+39 331 9012345', 'Ingegnere, mi trasferisco spesso', NULL, false, '[]', 'unverified', '{}', '{}'),
(10, 'sara.fontana@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Sara Fontana', '+39 344 0123456', 'Insegnante, estate libera per ristrutturazioni', NULL, false, '[]', 'unverified', '{}', '{}'),
(11, 'marco.galli@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Marco Galli', '+39 346 1234567', 'Manager, famiglia numerosa', NULL, false, '[]', 'unverified', '{}', '{}'),
(12, 'chiara.russo@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'client', 'Chiara Russo', '+39 349 2345678', 'Architetto, sto ristrutturando casa', NULL, false, '[]', 'unverified', '{}', '{}'),

-- Helpers (IDs 13-20)
(13, 'roberto.santoro@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Roberto Santoro', '+39 320 3456789', 'Tuttofare esperto, 15 anni di esperienza in piccoli lavori domestici', 25.00, true, '["idraulica", "elettricità", "montaggio mobili"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(14, 'vincenzo.de_luca@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Vincenzo De Luca', '+39 321 4567890', 'Imbianchino professionista, lavori impeccabili', 30.00, true, '["imbiancatura", "cartongesso", "stuccatura"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(15, 'antonio.esposito@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Antonio Esposito', '+39 322 5678901', 'Giardiniere appassionato, cura del verde a 360°', 20.00, true, '["giardinaggio", "potatura", "irrigazione"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(16, 'laura.costa@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Laura Costa', '+39 323 6789012', 'Pulizie professionali, case e uffici', 18.00, true, '["pulizie", "sanificazione", "stiratura"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(17, 'davide.bruno@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Davide Bruno', '+39 324 7890123', 'Traslocatore e facchino, forza e precisione', 22.00, true, '["traslochi", "sgomberi", "montaggio mobili"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(18, 'simone.greco@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Simone Greco', '+39 325 8901234', 'Elettricista certificato, impianti civili', 35.00, true, '["elettricità", "illuminazione", "domotica"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(19, 'federica.serra@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Federica Serra', '+39 326 9012345', 'Baby-sitter e aiuto compiti, paziente e affidabile', 15.00, false, '["baby-sitting", "aiuto compiti", "accompagnamento"]', 'verified', '{}', '{"stripe": true, "profile": true}'),
(20, 'matteo.lombardi@email.it', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4oaC3JFbqz6M.TlK', 'helper', 'Matteo Lombardi', '+39 327 0123456', 'Idraulico esperto, riparazioni rapide', 28.00, true, '["idraulica", "caldaie", "condizionatori"]', 'verified', '{}', '{"stripe": true, "profile": true}');

-- ============================================
-- TASKS (Various statuses, realistic scenarios)
-- Location: Rome area (approximate coordinates)
-- ============================================

INSERT INTO tasks (id, client_id, title, description, category, price_cents, status, version, location, address_line, city, urgency, created_at, expires_at, assigned_at, started_at, completed_at) VALUES

-- POSTED tasks (5) - waiting for offers
(1, 1, 'Montaggio libreria IKEA Billy', 'Ho acquistato una libreria IKEA Billy e ho bisogno di qualcuno che la monti. Include 5 ripiani, circa 2 ore di lavoro stimate.', 'Montaggio mobili', 6000, 'posted', 1, ST_SetSRID(ST_MakePoint(12.4963, 41.9028), 4326), 'Via del Corso 150', 'Roma', 'scheduled', NOW() - INTERVAL '2 hours', NOW() + INTERVAL '5 days', NULL, NULL, NULL),

(2, 2, 'Pulizia appartamento dopo festa', 'Ieri sera ho organizzato una festa e la casa è un disastro. Servono pulizie approfondite: soggiorno, cucina, 2 bagni. Circa 100mq.', 'Pulizie', 8500, 'posted', 1, ST_SetSRID(ST_MakePoint(12.4534, 41.9097), 4326), 'Viale Trastevere 78', 'Roma', 'asap', NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '1 day', NULL, NULL, NULL),

(3, 3, 'Aiuto trasloco studente', 'Mi trasferisco in un nuovo appartamento e ho bisogno di aiuto per portare scatoloni e mobili dal 3° piano senza ascensore. Circa 20 scatoloni + divano + letto singolo.', 'Traslochi', 15000, 'posted', 1, ST_SetSRID(ST_MakePoint(12.5118, 41.8919), 4326), 'Via Tiburtina 200', 'Roma', 'scheduled', NOW() - INTERVAL '1 day', NOW() + INTERVAL '7 days', NULL, NULL, NULL),

(4, 4, 'Potatura siepe giardino', 'La siepe del mio giardino è molto cresciuta, circa 15 metri lineari, altezza 2 metri. Vorrei rimetterla in ordine.', 'Giardinaggio', 12000, 'posted', 1, ST_SetSRID(ST_MakePoint(12.5673, 41.8723), 4326), 'Via Tuscolana 450', 'Roma', 'scheduled', NOW() - INTERVAL '3 days', NOW() + INTERVAL '14 days', NULL, NULL, NULL),

(5, 5, 'Riparazione rubinetto che gocciola', 'Il rubinetto della cucina gocciola costantemente. Probabilmente serve cambiare la guarnizione o la cartuccia.', 'Idraulica', 4500, 'posted', 1, ST_SetSRID(ST_MakePoint(12.4823, 41.9175), 4326), 'Via Cola di Rienzo 89', 'Roma', 'asap', NOW() - INTERVAL '4 hours', NOW() + INTERVAL '3 days', NULL, NULL, NULL),

-- ASSIGNING tasks (2) - offers received, selection in progress
(6, 6, 'Imbiancatura camera da letto', 'Camera da letto 4x4 metri, soffitto 2.7m. Pareti lisce, nessun lavoro preparatorio necessario. Colore bianco.', 'Imbiancatura', 25000, 'assigning', 1, ST_SetSRID(ST_MakePoint(12.4642, 41.9258), 4326), 'Via dei Gracchi 200', 'Roma', 'scheduled', NOW() - INTERVAL '2 days', NOW() + INTERVAL '10 days', NULL, NULL, NULL),

(7, 7, 'Installazione lampadario', 'Devo installare un lampadario nuovo nel soggiorno. Il punto luce c è già, ma il lampadario è abbastanza pesante (circa 8kg).', 'Elettricità', 5000, 'assigning', 1, ST_SetSRID(ST_MakePoint(12.4924, 41.9342), 4326), 'Piazza del Popolo 12', 'Roma', 'asap', NOW() - INTERVAL '1 day', NOW() + INTERVAL '2 days', NULL, NULL, NULL),

-- ASSIGNED tasks (3) - helper assigned, work not started yet
(8, 8, 'Montaggio cucina IKEA completa', 'Cucina IKEA Metod completa: 8 pensili, 6 basi, piano cottura e forno da incasso. Il materiale è già stato consegnato.', 'Montaggio mobili', 45000, 'assigned', 1, ST_SetSRID(ST_MakePoint(12.5015, 41.8847), 4326), 'Via Appia Nuova 300', 'Roma', 'scheduled', NOW() - INTERVAL '4 days', NOW() + INTERVAL '3 days', NOW() - INTERVAL '1 day', NULL, NULL),

(9, 9, 'Pulizia vetri condominio', 'Pulizia vetri del mio appartamento al 5° piano, 8 finestre grandi. Serve attrezzatura professionale.', 'Pulizie', 7000, 'assigned', 1, ST_SetSRID(ST_MakePoint(12.4458, 41.8924), 4326), 'Via Portuense 150', 'Roma', 'scheduled', NOW() - INTERVAL '3 days', NOW() + INTERVAL '2 days', NOW() - INTERVAL '2 days', NULL, NULL),

(10, 10, 'Sgombero cantina', 'Cantina da sgomberare, circa 20 mq. Tanti oggetti vecchi da portare in discarica. Accesso un po'' stretto.', 'Traslochi', 18000, 'assigned', 1, ST_SetSRID(ST_MakePoint(12.5234, 41.8765), 4326), 'Via Casilina 500', 'Roma', 'scheduled', NOW() - INTERVAL '5 days', NOW() + INTERVAL '4 days', NOW() - INTERVAL '3 days', NULL, NULL),

-- IN_PROGRESS tasks (4) - helper is currently working
(11, 11, 'Tinteggiatura balcone', 'Balcone di 6 mq, ringhiera in ferro da verniciare e muri da imbiancare. Il balcone è esposto a sud.', 'Imbiancatura', 15000, 'in_progress', 1, ST_SetSRID(ST_MakePoint(12.4756, 41.9087), 4326), 'Largo Argentina 5', 'Roma', 'scheduled', NOW() - INTERVAL '6 days', NOW() + INTERVAL '1 day', NOW() - INTERVAL '4 days', NOW() - INTERVAL '1 hour', NULL),

(12, 12, 'Riparazione perdita WC', 'Il WC ha una perdita alla base, probabilmente la guarnizione è vecchia. Serve intervenire urgentemente.', 'Idraulica', 8000, 'in_progress', 1, ST_SetSRID(ST_MakePoint(12.4892, 41.9012), 4326), 'Via Nazionale 100', 'Roma', 'asap', NOW() - INTERVAL '1 day', NOW() + INTERVAL '1 day', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '30 minutes', NULL),

(13, 1, 'Baby-sitting sabato sera', 'Cerco baby-sitter per sabato sera dalle 19 alle 24. Due bambini di 5 e 8 anni, tranquilli.', 'Baby-sitting', 6000, 'in_progress', 1, ST_SetSRID(ST_MakePoint(12.4963, 41.9028), 4326), 'Via del Corso 150', 'Roma', 'scheduled', NOW() - INTERVAL '3 days', NOW() + INTERVAL '0 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 hours', NULL),

(14, 2, 'Montaggio armadio PAX', 'Armadio IKEA PAX 2 ante scorrevoli, altezza 236cm. Già assemblato parzialmente.', 'Montaggio mobili', 7500, 'in_progress', 1, ST_SetSRID(ST_MakePoint(12.4534, 41.9097), 4326), 'Viale Trastevere 78', 'Roma', 'asap', NOW() - INTERVAL '2 days', NOW() + INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 hours', NULL),

-- IN_CONFIRMATION tasks (2) - work done, waiting for client confirmation
(15, 3, 'Pulizia dopo ristrutturazione', 'Appartamento appena ristrutturato, circa 80mq. Pulizia approfondita di polvere, calcinacci, residui di stucco.', 'Pulizie', 12000, 'in_confirmation', 1, ST_SetSRID(ST_MakePoint(12.5118, 41.8919), 4326), 'Via Tiburtina 200', 'Roma', 'scheduled', NOW() - INTERVAL '10 days', NOW() + INTERVAL '0 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '3 days', NULL),

(16, 4, 'Cura giardino mensile', 'Manutenzione mensile giardino: taglio erba, potatura arbusti, pulizia generale. Circa 200mq.', 'Giardinaggio', 20000, 'in_confirmation', 1, ST_SetSRID(ST_MakePoint(12.5673, 41.8723), 4326), 'Via Tuscolana 450', 'Roma', 'scheduled', NOW() - INTERVAL '14 days', NOW() + INTERVAL '0 days', NOW() - INTERVAL '10 days', NOW() - INTERVAL '5 days', NULL),

-- COMPLETED tasks (8) - successfully finished
(17, 5, 'Sostituzione serratura porta', 'Sostituzione serratura porta blindata con cilindro europeo di sicurezza.', 'Fabbro', 15000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4823, 41.9175), 4326), 'Via Cola di Rienzo 89', 'Roma', 'asap', NOW() - INTERVAL '20 days', NOW() - INTERVAL '17 days', NOW() - INTERVAL '19 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),

(18, 6, 'Pulizia profonda cucina', 'Pulizia approfondita cucina: sgrassatura mobili, forno, frigorifero, piano cottura.', 'Pulizie', 6000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4642, 41.9258), 4326), 'Via dei Gracchi 200', 'Roma', 'scheduled', NOW() - INTERVAL '15 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '14 days', NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),

(19, 7, 'Montaggio letto matrimoniale', 'Letto matrimoniale con testiera imbottita e contenitore. Marca Mondo Convenienza.', 'Montaggio mobili', 5500, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4924, 41.9342), 4326), 'Piazza del Popolo 12', 'Roma', 'scheduled', NOW() - INTERVAL '25 days', NOW() - INTERVAL '22 days', NOW() - INTERVAL '24 days', NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),

(20, 8, 'Installazione condizionatore', 'Installazione split 12000 BTU in camera da letto. Tutte le predisposizioni già presenti.', 'Condizionatori', 25000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.5015, 41.8847), 4326), 'Via Appia Nuova 300', 'Roma', 'scheduled', NOW() - INTERVAL '30 days', NOW() - INTERVAL '27 days', NOW() - INTERVAL '29 days', NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),

(21, 9, 'Trasloco ufficio piccolo', 'Trasloco ufficio: 4 scrivanie, 8 sedie, 2 armadi, vari scatoloni. Dal 2° al piano terra.', 'Traslochi', 35000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4458, 41.8924), 4326), 'Via Portuense 150', 'Roma', 'scheduled', NOW() - INTERVAL '35 days', NOW() - INTERVAL '32 days', NOW() - INTERVAL '34 days', NOW() - INTERVAL '33 days', NOW() - INTERVAL '33 days'),

(22, 10, 'Imbiancatura studio', 'Studio di 12mq, pareti e soffitto. Colore grigio perla.', 'Imbiancatura', 18000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.5234, 41.8765), 4326), 'Via Casilina 500', 'Roma', 'scheduled', NOW() - INTERVAL '40 days', NOW() - INTERVAL '35 days', NOW() - INTERVAL '38 days', NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days'),

(23, 11, 'Riparazione tapparella bloccata', 'Tapparella camera da letto bloccata a metà, non scende né sale.', 'Serramenti', 7000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4756, 41.9087), 4326), 'Largo Argentina 5', 'Roma', 'asap', NOW() - INTERVAL '45 days', NOW() - INTERVAL '43 days', NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),

(24, 12, 'Pulizia fine lavori cantiere', 'Pulizia finale appartamento dopo lavori edili. 120mq, molto sporco.', 'Pulizie', 15000, 'completed', 1, ST_SetSRID(ST_MakePoint(12.4892, 41.9012), 4326), 'Via Nazionale 100', 'Roma', 'scheduled', NOW() - INTERVAL '50 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '48 days', NOW() - INTERVAL '46 days', NOW() - INTERVAL '46 days'),

-- CANCELLED tasks (2)
(25, 1, 'Pittura staccionata giardino', 'Staccionata in legno da verniciare, circa 10 metri lineari.', 'Imbiancatura', 10000, 'cancelled_by_client', 1, ST_SetSRID(ST_MakePoint(12.4963, 41.9028), 4326), 'Via del Corso 150', 'Roma', 'scheduled', NOW() - INTERVAL '7 days', NOW() - INTERVAL '3 days', NULL, NULL, NULL),

(26, 5, 'Montaggio scaffali garage', 'Scaffalature metalliche per garage, 3 unità alte 2 metri.', 'Montaggio mobili', 9000, 'cancelled_by_helper', 1, ST_SetSRID(ST_MakePoint(12.4823, 41.9175), 4326), 'Via Cola di Rienzo 89', 'Roma', 'scheduled', NOW() - INTERVAL '8 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '6 days', NULL, NULL);

-- ============================================
-- TASK OFFERS (for ASSIGNING, ASSIGNED, IN_PROGRESS tasks)
-- ============================================

INSERT INTO task_offers (id, task_id, helper_id, status, price_cents, message, created_at) VALUES
-- Offers for task 6 (ASSIGNING - imbiancatura)
(1, 6, 14, 'submitted', 24000, 'Buongiorno! Sono disponibile per il lavoro. Ho esperienza decennale in imbiancatura, posso iniziare anche domani.', NOW() - INTERVAL '1 day'),
(2, 6, 13, 'submitted', 26000, 'Salve, posso occuparmene io. Includo anche la protezione dei mobili e pavimenti.', NOW() - INTERVAL '18 hours'),

-- Offers for task 7 (ASSIGNING - lampadario)
(3, 7, 18, 'submitted', 5000, 'Sono elettricista certificato, posso installare il lampadario in sicurezza oggi stesso.', NOW() - INTERVAL '20 hours'),
(4, 7, 13, 'submitted', 4500, 'Posso aiutarti con l installazione, ho tutto il necessario.', NOW() - INTERVAL '16 hours'),

-- Offers for task 8 (ASSIGNED - cucina IKEA) - one accepted
(5, 8, 13, 'accepted', 43000, 'Ho montato decine di cucine IKEA, conosco bene il sistema Metod. Lavoro garantito.', NOW() - INTERVAL '3 days'),
(6, 8, 17, 'declined', 48000, 'Sono disponibile, ma ho bisogno di un aiutante per i pensili alti.', NOW() - INTERVAL '3 days'),

-- Offers for task 9 (ASSIGNED - pulizia vetri)
(7, 9, 16, 'accepted', 7000, 'Ho tutta l attrezzatura professionale per vetri ad alta quota. Lavoro sempre in sicurezza.', NOW() - INTERVAL '2 days' - INTERVAL '6 hours'),

-- Offers for task 10 (ASSIGNED - sgombero cantina)
(8, 10, 17, 'accepted', 17000, 'Ho il furgone e posso portare tutto in discarica. Prezzo all-inclusive.', NOW() - INTERVAL '4 days'),

-- Offers for task 11 (IN_PROGRESS - balcone)
(9, 11, 14, 'accepted', 14500, 'Specializzato in esterni e ringhiere. Uso prodotti resistenti agli agenti atmosferici.', NOW() - INTERVAL '5 days'),

-- Offers for task 12 (IN_PROGRESS - WC)
(10, 12, 20, 'accepted', 8000, 'Problema risolvibile in poco tempo. Arrivo con tutti i ricambi necessari.', NOW() - INTERVAL '22 hours'),

-- Offers for task 13 (IN_PROGRESS - baby-sitting)
(11, 13, 19, 'accepted', 6000, 'Sono disponibile sabato sera! Amo stare con i bambini e posso anche preparare la cena per loro.', NOW() - INTERVAL '2 days' - INTERVAL '12 hours'),

-- Offers for task 14 (IN_PROGRESS - armadio PAX)
(12, 14, 13, 'accepted', 7500, 'PAX è la mia specialità, l ho montato centinaia di volte!', NOW() - INTERVAL '1 day' - INTERVAL '8 hours'),

-- Offers for task 15 (IN_CONFIRMATION - pulizia ristrutturazione)
(13, 15, 16, 'accepted', 12000, 'Pulizie post cantiere sono la mia specialità. Uso prodotti professionali per ogni superficie.', NOW() - INTERVAL '9 days'),

-- Offers for task 16 (IN_CONFIRMATION - giardino)
(14, 16, 15, 'accepted', 20000, 'Offro manutenzione regolare e garantisco un giardino sempre in ordine.', NOW() - INTERVAL '12 days');

-- ============================================
-- TASK ASSIGNMENTS (for ASSIGNED, IN_PROGRESS, IN_CONFIRMATION, COMPLETED tasks)
-- ============================================

INSERT INTO task_assignments (id, task_id, helper_id, status, assigned_at, completed_at) VALUES
(1, 8, 13, 'assigned', NOW() - INTERVAL '1 day', NULL),
(2, 9, 16, 'assigned', NOW() - INTERVAL '2 days', NULL),
(3, 10, 17, 'assigned', NOW() - INTERVAL '3 days', NULL),
(4, 11, 14, 'in_progress', NOW() - INTERVAL '4 days', NULL),
(5, 12, 20, 'in_progress', NOW() - INTERVAL '12 hours', NULL),
(6, 13, 19, 'in_progress', NOW() - INTERVAL '2 days', NULL),
(7, 14, 13, 'in_progress', NOW() - INTERVAL '1 day', NULL),
(8, 15, 16, 'completed', NOW() - INTERVAL '7 days', NOW() - INTERVAL '3 days'),
(9, 16, 15, 'completed', NOW() - INTERVAL '10 days', NOW() - INTERVAL '5 days'),
(10, 17, 13, 'completed', NOW() - INTERVAL '19 days', NOW() - INTERVAL '18 days'),
(11, 18, 16, 'completed', NOW() - INTERVAL '14 days', NOW() - INTERVAL '13 days'),
(12, 19, 13, 'completed', NOW() - INTERVAL '24 days', NOW() - INTERVAL '23 days'),
(13, 20, 18, 'completed', NOW() - INTERVAL '29 days', NOW() - INTERVAL '28 days'),
(14, 21, 17, 'completed', NOW() - INTERVAL '34 days', NOW() - INTERVAL '33 days'),
(15, 22, 14, 'completed', NOW() - INTERVAL '38 days', NOW() - INTERVAL '36 days'),
(16, 23, 13, 'completed', NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),
(17, 24, 16, 'completed', NOW() - INTERVAL '48 days', NOW() - INTERVAL '46 days');

-- Update tasks with selected_offer_id for assigned/in_progress tasks
UPDATE tasks SET selected_offer_id = 5 WHERE id = 8;
UPDATE tasks SET selected_offer_id = 7 WHERE id = 9;
UPDATE tasks SET selected_offer_id = 8 WHERE id = 10;
UPDATE tasks SET selected_offer_id = 9 WHERE id = 11;
UPDATE tasks SET selected_offer_id = 10 WHERE id = 12;
UPDATE tasks SET selected_offer_id = 11 WHERE id = 13;
UPDATE tasks SET selected_offer_id = 12 WHERE id = 14;
UPDATE tasks SET selected_offer_id = 13 WHERE id = 15;
UPDATE tasks SET selected_offer_id = 14 WHERE id = 16;

-- ============================================
-- REVIEWS (for completed tasks)
-- ============================================

INSERT INTO reviews (task_id, from_user_id, to_user_id, stars, comment, created_at) VALUES
-- Reviews for completed tasks (client reviews helper, helper reviews client)
(17, 5, 13, 5, 'Lavoro perfetto! Veloce e professionale, la serratura funziona benissimo.', NOW() - INTERVAL '17 days'),
(17, 13, 5, 5, 'Cliente puntuale e gentile, pagamento immediato.', NOW() - INTERVAL '17 days'),

(18, 6, 16, 5, 'Cucina splendente! Laura è bravissima e molto precisa.', NOW() - INTERVAL '12 days'),
(18, 16, 6, 5, 'Bellissima casa, cliente molto cordiale.', NOW() - INTERVAL '12 days'),

(19, 7, 13, 4, 'Buon lavoro, il letto è solido. Solo un po'' di ritardo nell arrivo.', NOW() - INTERVAL '22 days'),
(19, 13, 7, 5, 'Cliente disponibile, tutto in ordine.', NOW() - INTERVAL '22 days'),

(20, 8, 18, 5, 'Condizionatore installato perfettamente, fresco e silenzioso!', NOW() - INTERVAL '27 days'),
(20, 18, 8, 5, 'Ottimo cliente, aveva già tutto predisposto.', NOW() - INTERVAL '27 days'),

(21, 9, 17, 5, 'Trasloco impeccabile, nessun danno e velocissimi!', NOW() - INTERVAL '32 days'),
(21, 17, 9, 4, 'Buon cliente, però c erano più cose del previsto.', NOW() - INTERVAL '32 days'),

(22, 10, 14, 5, 'Studio bellissimo, il grigio perla è perfetto!', NOW() - INTERVAL '35 days'),
(22, 14, 10, 5, 'Cliente con ottimo gusto, facile lavorare con lei.', NOW() - INTERVAL '35 days'),

(23, 11, 13, 5, 'Tapparella riparata in 15 minuti! Fantastico.', NOW() - INTERVAL '43 days'),
(23, 13, 11, 5, 'Problema semplice, cliente molto grato.', NOW() - INTERVAL '43 days'),

(24, 12, 16, 5, 'Casa pulitissima dopo il cantiere, lavoro straordinario.', NOW() - INTERVAL '45 days'),
(24, 16, 12, 5, 'Grande appartamento, cliente molto professionale.', NOW() - INTERVAL '45 days');

-- ============================================
-- TASK THREADS & MESSAGES (sample conversations)
-- ============================================

-- Thread for task 1 (posted) - potential helper asking questions
INSERT INTO task_threads (id, task_id, client_id, helper_id, created_at) VALUES
(1, 1, 1, 13, NOW() - INTERVAL '1 hour');

INSERT INTO task_messages (thread_id, sender_id, type, body, created_at) VALUES
(1, 13, 'text', 'Buongiorno! La libreria è già stata consegnata o devo ritirarla io?', NOW() - INTERVAL '55 minutes'),
(1, 1, 'text', 'Ciao Roberto! Sì, è già a casa mia, tutti i pacchi sono in soggiorno.', NOW() - INTERVAL '50 minutes'),
(1, 13, 'text', 'Perfetto! Avete anche un trapano a disposizione o devo portare tutto io?', NOW() - INTERVAL '45 minutes'),
(1, 1, 'text', 'Ho un trapano base, ma forse è meglio se porti il tuo professionale.', NOW() - INTERVAL '40 minutes');

-- Thread for task 6 (assigning) - negotiation
INSERT INTO task_threads (id, task_id, client_id, helper_id, created_at) VALUES
(2, 6, 6, 14, NOW() - INTERVAL '1 day');

INSERT INTO task_messages (thread_id, sender_id, type, body, created_at) VALUES
(2, 14, 'text', 'Buongiorno Francesca, ho visto la richiesta per la camera da letto. Posso fare un ottimo lavoro!', NOW() - INTERVAL '23 hours'),
(2, 6, 'text', 'Ciao Vincenzo! Che tipo di vernice usi?', NOW() - INTERVAL '22 hours'),
(2, 14, 'text', 'Uso vernici traspiranti certificate, ottime per le camere da letto. Nessun odore sgradevole.', NOW() - INTERVAL '21 hours'),
(2, 6, 'text', 'Fantastico! Quanto tempo ci vorrebbe?', NOW() - INTERVAL '20 hours'),
(2, 14, 'text', 'Per una stanza di quelle dimensioni, una giornata di lavoro. Il giorno dopo si può già riarredare.', NOW() - INTERVAL '19 hours'),
(2, 14, 'offer_update', NULL, NOW() - INTERVAL '1 day'),
(2, 6, 'text', 'Grazie, sto valutando anche altre offerte e ti faccio sapere!', NOW() - INTERVAL '18 hours');

-- Thread for task 11 (in_progress) - work updates
INSERT INTO task_threads (id, task_id, client_id, helper_id, created_at) VALUES
(3, 11, 11, 14, NOW() - INTERVAL '4 days');

INSERT INTO task_messages (thread_id, sender_id, type, body, created_at) VALUES
(3, 14, 'text', 'Sono arrivato, inizio con la preparazione della ringhiera.', NOW() - INTERVAL '1 hour'),
(3, 11, 'text', 'Perfetto! Ti lascio lavorare, sono in casa se hai bisogno.', NOW() - INTERVAL '55 minutes'),
(3, 14, 'text', 'Ho finito la prima mano sulla ringhiera. Domani la seconda mano e poi i muri.', NOW() - INTERVAL '30 minutes'),
(3, 11, 'text', 'Ottimo! Il colore sta venendo molto bene!', NOW() - INTERVAL '25 minutes');

-- Update sequences to avoid conflicts
SELECT setval('users_id_seq', 20);
SELECT setval('tasks_id_seq', 26);
SELECT setval('task_offers_id_seq', 14);
SELECT setval('task_assignments_id_seq', 17);
SELECT setval('task_threads_id_seq', 3);
SELECT setval('task_messages_id_seq', 15);

SELECT 'Database seeded successfully!' as status;
