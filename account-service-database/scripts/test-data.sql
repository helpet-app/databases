INSERT INTO accounts (id, username, password, name, email)
VALUES ('27a7da73-0c71-4157-b272-3166d1432951', 'a.sergeev', '$2a$12$7o025D9I30k5Ka9Clkuy7eQVt3ouPOpOOo2C.kZZjgw4ixEAPKkcG',
        'Сергеев Александр Викторович', 'a.sergeev@mail.ru'),
       ('202b727d-b383-46a6-93e3-5e1e95454295', 'm.petrova', '$2a$12$W7U18bfdR.u3WsQa1J62ZudT/rEFuGPoU7ZzqHo6vT81IGPW8s0Zu',
        'Петрова Мария Сергеевна', 'm.petrova@mail.ru'),
       ('79bb62ae-b7ca-4311-b643-febdf5e8f0b3', 'o.sidorova', '$2a$12$eMMY3u3O3p1uQapsYS38POxzpXTbzyLr84Ac5OW/u.mp5doi7VW/C',
        'Сидорова Ольга Николаевна', 'o.sidorova@mail.ru'),
       ('b7edb4f6-d6e3-40ea-a696-89030aa48457', 's.ivanov', '$2a$12$y0l1wA6m5w6Hdhi.pU/0EOAzqMIh3yjIGrnzXYqxWUGKZIaDTSC4O',
        'Иванов Сергей Александрович', 's.ivanov@mail.ru'),
       ('7b9ddbfb-3c92-4db6-9ede-262d5bc49db6', 'v.sidorov', '$2a$12$7C8JAHS8Csvu9RGf2axv8O.swfIs7Nm3bl8kwNq3mXx0C8/yZtOTS',
        'Сидоров Иван Дмитриевич', 'v.sidorov@mail.ru');

INSERT INTO account_roles (account_id, role)
VALUES ('27a7da73-0c71-4157-b272-3166d1432951', 'USER'),
       ('202b727d-b383-46a6-93e3-5e1e95454295', 'USER'),
       ('79bb62ae-b7ca-4311-b643-febdf5e8f0b3', 'USER'),
       ('b7edb4f6-d6e3-40ea-a696-89030aa48457', 'USER'),
       ('7b9ddbfb-3c92-4db6-9ede-262d5bc49db6', 'USER');

INSERT INTO account_roles (account_id, role)
VALUES ('27a7da73-0c71-4157-b272-3166d1432951', 'ADMIN');

INSERT INTO account_roles (account_id, role)
VALUES ('27a7da73-0c71-4157-b272-3166d1432951', 'MODERATOR');

INSERT INTO account_roles (account_id, role)
VALUES ('27a7da73-0c71-4157-b272-3166d1432951', 'VET'),
       ('202b727d-b383-46a6-93e3-5e1e95454295', 'VET'),
       ('b7edb4f6-d6e3-40ea-a696-89030aa48457', 'VET');

INSERT INTO account_bans (id, account_id, moderator_id, blocked_at, unblocked_at, reason)
VALUES (DEFAULT, '7b9ddbfb-3c92-4db6-9ede-262d5bc49db6', 'ce4ddbee-425d-4382-b21f-63dfed8d61bf', NOW(), NULL, 'Неадекватное поведение');