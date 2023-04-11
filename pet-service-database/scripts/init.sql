CREATE TABLE accounts (
    id         UUID PRIMARY KEY,
    username   TEXT NOT NULL,
    name       TEXT NOT NULL,
    avatar_url TEXT
);
CREATE UNIQUE INDEX accounts_unique_username ON accounts (UPPER(username));

-- CREATE SUBSCRIPTION accounts_subscription_for_pet_service CONNECTION '...' PUBLICATION accounts_publication;

CREATE TABLE families (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES accounts (id)
);

CREATE TABLE user_families (
    user_id   UUID REFERENCES accounts (id),
    family_id UUID REFERENCES families (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, family_id)
);
CREATE UNIQUE INDEX user_families_pkey_reverse ON user_families (family_id, user_id);

CREATE TABLE pet_categories (
    id   INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name TEXT NOT NULL UNIQUE
);
CREATE INDEX pet_categories_name ON pet_categories (UPPER(name));

CREATE TABLE species (
    id              INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
    name            TEXT NOT NULL,
    pet_category_id INTEGER NOT NULL REFERENCES pet_categories (id) ON DELETE CASCADE,
    UNIQUE (name, pet_category_id)
);
CREATE INDEX species_pet_category_fkey ON species (pet_category_id);
CREATE INDEX species_name ON species (UPPER(name));

CREATE TYPE gender AS ENUM ('BOY', 'GIRL');
CREATE CAST (VARCHAR AS gender) WITH INOUT AS IMPLICIT;

CREATE TABLE pets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    avatar_url      TEXT,
    gender          gender,
    date_of_birth   DATE,
    is_sterilized   BOOLEAN,
    chip_number     TEXT,
    pet_category_id INTEGER REFERENCES pet_categories (id) ON DELETE SET NULL,
    species_id      INTEGER REFERENCES species (id) ON DELETE SET NULL,
    family_id       UUID REFERENCES families (id) ON DELETE SET NULL,
    created_by      UUID NOT NULL REFERENCES accounts (id)
);
CREATE INDEX pets_created_by_fkey ON pets (created_by);
CREATE INDEX pets_family_fkey ON pets (family_id);

CREATE TABLE pet_features (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    description TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID NOT NULL REFERENCES accounts (id),
    pet_id      UUID NOT NULL REFERENCES pets (id) ON DELETE CASCADE
);
CREATE INDEX pet_features_pet_fkey ON pet_features (pet_id);

CREATE TABLE pet_anthropometry_history (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    height     DOUBLE PRECISION NOT NULL,
    weight     DOUBLE PRECISION NOT NULL,
    comment    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES accounts (id),
    pet_id     UUID NOT NULL REFERENCES pets (id) ON DELETE CASCADE
);
CREATE INDEX pet_anthropometry_history_pet_fkey ON pet_anthropometry_history (pet_id);

CREATE TABLE pet_disease_history (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    disease_name TEXT NOT NULL,
    comment      TEXT,
    got_sick_on  DATE NOT NULL,
    recovered_on DATE CHECK (recovered_on >= got_sick_on),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by   UUID NOT NULL REFERENCES accounts (id),
    pet_id       UUID NOT NULL REFERENCES pets (id) ON DELETE CASCADE
);
CREATE INDEX pet_disease_history_pet_fkey ON pet_disease_history (pet_id);

CREATE TABLE pet_vaccination_history (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vaccination_name TEXT NOT NULL,
    comment          TEXT,
    vaccinated_on    DATE NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       UUID NOT NULL REFERENCES accounts (id),
    pet_id           UUID NOT NULL REFERENCES pets (id) ON DELETE CASCADE
);
CREATE INDEX pet_vaccination_history_pet_fkey ON pet_vaccination_history (pet_id);

CREATE FUNCTION find_all_pets_associated_with_user(user_id UUID)
    RETURNS SETOF pets
AS
$$
BEGIN
    RETURN QUERY
        SELECT p.*
        FROM pets AS p
                 INNER JOIN user_families AS uf ON p.family_id = uf.family_id
        WHERE uf.user_id = $1
        UNION
        SELECT p.*
        FROM pets AS p
        WHERE p.created_by = $1;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION pet_is_associated_with_user(pet_id UUID, user_id UUID)
    RETURNS BOOLEAN
AS
$$
BEGIN
    RETURN EXISTS(SELECT 1
                  FROM pets AS p
                  WHERE p.id = $1
                    AND p.created_by = $2) OR
           EXISTS(SELECT 1
                  FROM pets AS p
                           INNER JOIN user_families AS uf ON p.family_id = uf.family_id
                  WHERE p.id = $1
                    AND uf.user_id = $2);
END;
$$ LANGUAGE PLPGSQL;

INSERT INTO pet_categories (id, name)
VALUES (DEFAULT, 'Собаки'),
       (DEFAULT, 'Кошки'),
       (DEFAULT, 'Морские свинки'),
       (DEFAULT, 'Мыши'),
       (DEFAULT, 'Крысы'),
       (DEFAULT, 'Кролики'),
       (DEFAULT, 'Попугаи'),
       (DEFAULT, 'Пауки');

INSERT INTO species (id, name, pet_category_id)
VALUES (DEFAULT, 'Австралийская короткохвостая пастушья собака', 1),
       (DEFAULT, 'Австралийская овчарка', 1),
       (DEFAULT, 'Австралийская пастушья собака', 1),
       (DEFAULT, 'Австралийский келпи', 1),
       (DEFAULT, 'Австралийский терьер', 1),
       (DEFAULT, 'Австралийский шелковистый терьер', 1),
       (DEFAULT, 'Австрийская гончая', 1),
       (DEFAULT, 'Австрийский брудастый бракк', 1),
       (DEFAULT, 'Австрийский пинчер', 1),
       (DEFAULT, 'Азавак', 1),
       (DEFAULT, 'Азорская пастушья собака', 1),
       (DEFAULT, 'Аиди', 1),
       (DEFAULT, 'Акита-ину', 1),
       (DEFAULT, 'Алан', 1),
       (DEFAULT, 'Алано', 1),
       (DEFAULT, 'Алапахский бульдог', 1),
       (DEFAULT, 'Алопекис', 1),
       (DEFAULT, 'Альпийская таксообразная гончая', 1),
       (DEFAULT, 'Аляскинский кли-кай', 1),
       (DEFAULT, 'Аляскинский маламут', 1),
       (DEFAULT, 'Американская акита', 1),
       (DEFAULT, 'Американская эскимосская собака', 1),
       (DEFAULT, 'Американский бандог', 1),
       (DEFAULT, 'Американский булли', 1),
       (DEFAULT, 'Американский бульдог', 1),
       (DEFAULT, 'Американский водяной спаниель', 1),
       (DEFAULT, 'Американский голый терьер', 1),
       (DEFAULT, 'Американский кокер-спаниель', 1),
       (DEFAULT, 'Американский мастиф', 1),
       (DEFAULT, 'Американский питбультерьер', 1),
       (DEFAULT, 'Американский стаффордширский терьер', 1),
       (DEFAULT, 'Американский фоксхаунд', 1),
       (DEFAULT, 'Анатолийская овчарка', 1),
       (DEFAULT, 'Английская енотовая гончая', 1),
       (DEFAULT, 'Английская овчарка', 1),
       (DEFAULT, 'Английский бульдог', 1),
       (DEFAULT, 'Английский водяной спаниель', 1),
       (DEFAULT, 'Английский кокер-спаниель', 1),
       (DEFAULT, 'Английский мастиф', 1),
       (DEFAULT, 'Английский пойнтер', 1),
       (DEFAULT, 'Английский сеттер', 1),
       (DEFAULT, 'Английский спрингер-спаниель', 1),
       (DEFAULT, 'Английский той-терьер', 1),
       (DEFAULT, 'Английский фоксхаунд', 1),
       (DEFAULT, 'Англо-французская малая гончая', 1),
       (DEFAULT, 'Андалузский поденко', 1),
       (DEFAULT, 'Аппенцеллер зенненхунд', 1),
       (DEFAULT, 'Аргентинский дог', 1),
       (DEFAULT, 'Арденнский бувье', 1),
       (DEFAULT, 'Артезиано-нормандский бассет', 1),
       (DEFAULT, 'Артуазская гончая', 1),
       (DEFAULT, 'Арьежская гончая', 1),
       (DEFAULT, 'Афганская борзая', 1),
       (DEFAULT, 'Африканис', 1),
       (DEFAULT, 'Аффенпинчер', 1),
       (DEFAULT, 'Баварская горная гончая', 1),
       (DEFAULT, 'Бакхмуль', 1),
       (DEFAULT, 'Барбет', 1),
       (DEFAULT, 'Басенджи', 1),
       (DEFAULT, 'Баскская овчарка', 1),
       (DEFAULT, 'Бассет-хаунд', 1),
       (DEFAULT, 'Бедлингтон-терьер', 1),
       (DEFAULT, 'Белая швейцарская овчарка', 1),
       (DEFAULT, 'Бельгийская овчарка', 1),
       (DEFAULT, 'Бельгийский гриффон', 1),
       (DEFAULT, 'Бергамская овчарка', 1),
       (DEFAULT, 'Бернская гончая', 1),
       (DEFAULT, 'Бернский зенненхунд', 1),
       (DEFAULT, 'Бивер-йоркширский терьер', 1),
       (DEFAULT, 'Бигль', 1),
       (DEFAULT, 'Бишон-фризе', 1),
       (DEFAULT, 'Бладхаунд', 1),
       (DEFAULT, 'Блю-лейси', 1),
       (DEFAULT, 'Бобтейл', 1),
       (DEFAULT, 'Болгарская гончая', 1),
       (DEFAULT, 'Болгарский барак', 1),
       (DEFAULT, 'Болоньез', 1),
       (DEFAULT, 'Большой вандейский бассет-гриффон', 1),
       (DEFAULT, 'Большой вандейский гриффон', 1),
       (DEFAULT, 'Большой мюнстерлендер', 1),
       (DEFAULT, 'Большой швейцарский зенненхунд', 1),
       (DEFAULT, 'Бордер-колли', 1),
       (DEFAULT, 'Бордер-терьер', 1),
       (DEFAULT, 'Бордоский дог', 1),
       (DEFAULT, 'Бородатый колли', 1),
       (DEFAULT, 'Босерон', 1),
       (DEFAULT, 'Бостон-терьер', 1),
       (DEFAULT, 'Бразильский терьер', 1),
       (DEFAULT, 'Бразильский фила', 1),
       (DEFAULT, 'Бретонский эпаньоль', 1),
       (DEFAULT, 'Бриар', 1),
       (DEFAULT, 'Брохольмер', 1),
       (DEFAULT, 'Брюссельский гриффон', 1),
       (DEFAULT, 'Буковинская овчарка', 1),
       (DEFAULT, 'Бульдог кампейро', 1),
       (DEFAULT, 'Бульдог Катахулы', 1),
       (DEFAULT, 'Бульмастиф', 1),
       (DEFAULT, 'Бультерьер', 1),
       (DEFAULT, 'Бурбонский бракк', 1),
       (DEFAULT, 'Бурбуль', 1),
       (DEFAULT, 'Бурят-монгольский волкодав', 1),
       (DEFAULT, 'Валенсийский ратер', 1),
       (DEFAULT, 'Вандейский бассет-гриффон', 1),
       (DEFAULT, 'Веймаранер', 1),
       (DEFAULT, 'Вельш-корги', 1),
       (DEFAULT, 'Вельш-спрингер-спаниель', 1),
       (DEFAULT, 'Вельштерьер', 1),
       (DEFAULT, 'Венгерская борзая', 1),
       (DEFAULT, 'Венгерская выжла', 1),
       (DEFAULT, 'Венгерская жесткошёрстная выжла', 1),
       (DEFAULT, 'Вертельная собака', 1),
       (DEFAULT, 'Вест-хайленд-уайт-терьер', 1),
       (DEFAULT, 'Веттерхун', 1),
       (DEFAULT, 'Волчья собака Сарлоса', 1),
       (DEFAULT, 'Вольпино итальяно', 1),
       (DEFAULT, 'Восточноевропейская овчарка', 1),
       (DEFAULT, 'Восточносибирская лайка', 1),
       (DEFAULT, 'Гаванский бишон', 1),
       (DEFAULT, 'Гамильтонстёваре', 1),
       (DEFAULT, 'Гампр', 1),
       (DEFAULT, 'Гладкошёрстный фокстерьер', 1),
       (DEFAULT, 'Глен оф Имаал терьер', 1),
       (DEFAULT, 'Голландская овчарка', 1),
       (DEFAULT, 'Голландский смоусхонд', 1),
       (DEFAULT, 'Голубой гасконский бассет', 1),
       (DEFAULT, 'Гончая Шиллера', 1),
       (DEFAULT, 'Грейхаунд', 1),
       (DEFAULT, 'Гренландская собака', 1),
       (DEFAULT, 'Греческая овчарка', 1),
       (DEFAULT, 'Гриффон Кортальса', 1),
       (DEFAULT, 'Грюнендаль', 1),
       (DEFAULT, 'Далматин', 1),
       (DEFAULT, 'Датско-шведская фермерская собака', 1),
       (DEFAULT, 'Денди-динмонт-терьер', 1),
       (DEFAULT, 'Джек-рассел-терьер', 1),
       (DEFAULT, 'Дзёмон-сиба', 1),
       (DEFAULT, 'Дирхаунд', 1),
       (DEFAULT, 'Длинношёрстный колли', 1),
       (DEFAULT, 'Доберман', 1),
       (DEFAULT, 'Дратхаар', 1),
       (DEFAULT, 'Древер', 1),
       (DEFAULT, 'Дункер', 1),
       (DEFAULT, 'Евразиер', 1),
       (DEFAULT, 'Жесткошёрстный фокстерьер', 1),
       (DEFAULT, 'Западносибирская лайка', 1),
       (DEFAULT, 'Золотистый ретривер', 1),
       (DEFAULT, 'Ирландский водяной спаниель', 1),
       (DEFAULT, 'Ирландский волкодав', 1),
       (DEFAULT, 'Ирландский красный сеттер', 1),
       (DEFAULT, 'Ирландский мягкошёрстный пшеничный терьер', 1),
       (DEFAULT, 'Ирландский терьер', 1),
       (DEFAULT, 'Исландская собака', 1),
       (DEFAULT, 'Испанская водяная собака', 1),
       (DEFAULT, 'Испанская гончая', 1),
       (DEFAULT, 'Испанский гальго', 1),
       (DEFAULT, 'Испанский мастиф', 1),
       (DEFAULT, 'Итальянская гончая', 1),
       (DEFAULT, 'Итальянский бракк', 1),
       (DEFAULT, 'Итальянский спиноне', 1),
       (DEFAULT, 'Йоркширский терьер', 1),
       (DEFAULT, 'Ка-де-бо', 1),
       (DEFAULT, 'Кавалер-кинг-чарльз-спаниель', 1),
       (DEFAULT, 'Кавказская овчарка', 1),
       (DEFAULT, 'Каи', 1),
       (DEFAULT, 'Кан де паллейро', 1),
       (DEFAULT, 'Канадская эскимосская собака', 1),
       (DEFAULT, 'Канарский дог', 1),
       (DEFAULT, 'Кане-корсо', 1),
       (DEFAULT, 'Као де кастро-лаборейро', 1),
       (DEFAULT, 'Каракачанская собака', 1),
       (DEFAULT, 'Карело-финская лайка', 1),
       (DEFAULT, 'Карельская лайка', 1),
       (DEFAULT, 'Карельская медвежья собака', 1),
       (DEFAULT, 'Карликовый пинчер', 1),
       (DEFAULT, 'Каталонская овчарка', 1),
       (DEFAULT, 'Кеесхонд', 1),
       (DEFAULT, 'Керн-терьер', 1),
       (DEFAULT, 'Керри-блю-терьер', 1),
       (DEFAULT, 'Кинг-чарльз-спаниель', 1),
       (DEFAULT, 'Кинтамани', 1),
       (DEFAULT, 'Кисю', 1),
       (DEFAULT, 'Китайская хохлатая собака', 1),
       (DEFAULT, 'Китайский чунцин', 1),
       (DEFAULT, 'Кламбер-спаниель', 1),
       (DEFAULT, 'Коикерхондье', 1),
       (DEFAULT, 'Комондор', 1),
       (DEFAULT, 'Континентальный бульдог', 1),
       (DEFAULT, 'Континентальный той-спаниель', 1),
       (DEFAULT, 'Корейский чиндо', 1),
       (DEFAULT, 'Короткошёрстный колли', 1),
       (DEFAULT, 'Котон-де-тулеар', 1),
       (DEFAULT, 'Крашская овчарка', 1),
       (DEFAULT, 'Кромфорлендер', 1),
       (DEFAULT, 'Ксолоитцкуинтли', 1),
       (DEFAULT, 'Кубинский дог', 1),
       (DEFAULT, 'Кувас', 1),
       (DEFAULT, 'Кули', 1),
       (DEFAULT, 'Куньминская овчарка', 1),
       (DEFAULT, 'Кури (собака)', 1),
       (DEFAULT, 'Курцхаар', 1),
       (DEFAULT, 'Курчавошёрстный ретривер', 1),
       (DEFAULT, 'Лабрадор-ретривер', 1),
       (DEFAULT, 'Лабрадудль', 1),
       (DEFAULT, 'Лаготто-романьоло', 1),
       (DEFAULT, 'Лангхаар', 1),
       (DEFAULT, 'Ландсир', 1),
       (DEFAULT, 'Ланкаширский хилер', 1),
       (DEFAULT, 'Левретка', 1),
       (DEFAULT, 'Лейкленд-терьер', 1),
       (DEFAULT, 'Леонбергер', 1),
       (DEFAULT, 'Леопардовая собака Катахулы', 1),
       (DEFAULT, 'Лопарская оленегонная собака', 1),
       (DEFAULT, 'Лхасский апсо', 1),
       (DEFAULT, 'Майоркская овчарка', 1),
       (DEFAULT, 'Малая львиная собака', 1),
       (DEFAULT, 'Малая швейцарская гончая', 1),
       (DEFAULT, 'Малые бельгийские собаки', 1),
       (DEFAULT, 'Малый вандейский бассет-гриффон', 1),
       (DEFAULT, 'Малый мюнстерлендер', 1),
       (DEFAULT, 'Мальтийская болонка', 1),
       (DEFAULT, 'Манчестер-терьер', 1),
       (DEFAULT, 'Мареммо-абруццкая овчарка', 1),
       (DEFAULT, 'Махореро', 1),
       (DEFAULT, 'Меделян', 1),
       (DEFAULT, 'Миниатюрная американская овчарка', 1),
       (DEFAULT, 'Миттельшнауцер', 1),
       (DEFAULT, 'Мопс', 1),
       (DEFAULT, 'Московская сторожевая', 1),
       (DEFAULT, 'Муди', 1),
       (DEFAULT, 'Нагази', 1),
       (DEFAULT, 'Неаполитанский мастиф', 1),
       (DEFAULT, 'Немецкая овчарка', 1),
       (DEFAULT, 'Немецкий боксёр', 1),
       (DEFAULT, 'Немецкий вахтельхунд', 1),
       (DEFAULT, 'Немецкий дог', 1),
       (DEFAULT, 'Немецкий пинчер', 1),
       (DEFAULT, 'Немецкий шпиц', 1),
       (DEFAULT, 'Немецкий штихельхаар', 1),
       (DEFAULT, 'Немецкий ягдтерьер', 1),
       (DEFAULT, 'Ненецкая лайка', 1),
       (DEFAULT, 'Новозеландская овчарка', 1),
       (DEFAULT, 'Новошотландский ретривер', 1),
       (DEFAULT, 'Норботтен-шпиц', 1),
       (DEFAULT, 'Норвежский бухунд', 1),
       (DEFAULT, 'Норвежский лундехунд', 1),
       (DEFAULT, 'Норвежский серый элкхунд', 1),
       (DEFAULT, 'Норвежский чёрный элкхунд', 1),
       (DEFAULT, 'Норвич-терьер', 1),
       (DEFAULT, 'Норфолк-спаниель', 1),
       (DEFAULT, 'Норфолк-терьер', 1),
       (DEFAULT, 'Ньюфаундленд', 1),
       (DEFAULT, 'Овернский бракк', 1),
       (DEFAULT, 'Одис', 1),
       (DEFAULT, 'Оттерхаунд', 1),
       (DEFAULT, 'Пагль', 1),
       (DEFAULT, 'Папийон', 1),
       (DEFAULT, 'Парсон-рассел-терьер', 1),
       (DEFAULT, 'Паттердейл-терьер', 1),
       (DEFAULT, 'Пекинес', 1),
       (DEFAULT, 'Перуанская голая собака', 1),
       (DEFAULT, 'Пикардийская овчарка', 1),
       (DEFAULT, 'Пикардийский спаниель', 1),
       (DEFAULT, 'Пиренейская горная собака', 1),
       (DEFAULT, 'Пиренейская овчарка', 1),
       (DEFAULT, 'Пиренейский мастиф', 1),
       (DEFAULT, 'Поденко ибиценко', 1),
       (DEFAULT, 'Поденко канарио', 1),
       (DEFAULT, 'Польская гончая', 1),
       (DEFAULT, 'Польская низинная овчарка', 1),
       (DEFAULT, 'Польская подгалянская овчарка', 1),
       (DEFAULT, 'Польский огар', 1),
       (DEFAULT, 'Польский харт', 1),
       (DEFAULT, 'Померанский шпиц', 1),
       (DEFAULT, 'Помски', 1),
       (DEFAULT, 'Португальская водяная собака', 1),
       (DEFAULT, 'Португальская овчарка', 1),
       (DEFAULT, 'Португальский поденгу', 1),
       (DEFAULT, 'Пражский крысарик', 1),
       (DEFAULT, 'Прямошёрстный ретривер', 1),
       (DEFAULT, 'Пти-брабансон', 1),
       (DEFAULT, 'Пудель', 1),
       (DEFAULT, 'Пули', 1),
       (DEFAULT, 'Пуми', 1),
       (DEFAULT, 'Пхунсан', 1),
       (DEFAULT, 'Раджапалайям', 1),
       (DEFAULT, 'Рафейру ду Алентежу', 1),
       (DEFAULT, 'Ризеншнауцер', 1),
       (DEFAULT, 'Родезийский риджбек', 1),
       (DEFAULT, 'Ротвейлер', 1),
       (DEFAULT, 'Румынская карпатская овчарка', 1),
       (DEFAULT, 'Румынская миоритская овчарка', 1),
       (DEFAULT, 'Русская гончая', 1),
       (DEFAULT, 'Русская псовая борзая', 1),
       (DEFAULT, 'Русская салонная собака', 1),
       (DEFAULT, 'Русская цветная болонка', 1),
       (DEFAULT, 'Русский охотничий спаниель', 1),
       (DEFAULT, 'Русский той', 1),
       (DEFAULT, 'Русско-европейская лайка', 1),
       (DEFAULT, 'Рэт-терьер', 1),
       (DEFAULT, 'Рюкю', 1),
       (DEFAULT, 'Салюки', 1),
       (DEFAULT, 'Самоедская собака', 1),
       (DEFAULT, 'Сахалинский хаски', 1),
       (DEFAULT, 'Северная инуитская собака', 1),
       (DEFAULT, 'Сенбернар', 1),
       (DEFAULT, 'Сиба-ину', 1),
       (DEFAULT, 'Сибирский хаски', 1),
       (DEFAULT, 'Сикоку', 1),
       (DEFAULT, 'Силихем-терьер', 1),
       (DEFAULT, 'Скайтерьер', 1),
       (DEFAULT, 'Словацкий копов', 1),
       (DEFAULT, 'Словацкий чувач', 1),
       (DEFAULT, 'Слюги', 1),
       (DEFAULT, 'Смоландская гончая', 1),
       (DEFAULT, 'Среднеазиатская овчарка', 1),
       (DEFAULT, 'Средний вандейский гриффон', 1),
       (DEFAULT, 'Староанглийский бульдог', 1),
       (DEFAULT, 'Староанглийский бульдог (заново созданный)', 1),
       (DEFAULT, 'Староанглийский терьер', 1),
       (DEFAULT, 'Стародатский пойнтер', 1),
       (DEFAULT, 'Стаффордширский бультерьер', 1),
       (DEFAULT, 'Суссекс-спаниель', 1),
       (DEFAULT, 'Схипперке', 1),
       (DEFAULT, 'Тазы', 1),
       (DEFAULT, 'Тайваньская собака', 1),
       (DEFAULT, 'Тайган', 1),
       (DEFAULT, 'Тайский бангку', 1),
       (DEFAULT, 'Тайский риджбек', 1),
       (DEFAULT, 'Такса', 1),
       (DEFAULT, 'Тедди-рузвельт-терьер', 1),
       (DEFAULT, 'Теломиан', 1),
       (DEFAULT, 'Тентерфилд-терьер', 1),
       (DEFAULT, 'Течичи', 1),
       (DEFAULT, 'Тибетский мастиф', 1),
       (DEFAULT, 'Тибетский спаниель', 1),
       (DEFAULT, 'Тибетский терьер', 1),
       (DEFAULT, 'Той-бульдог', 1),
       (DEFAULT, 'Той-фокстерьер', 1),
       (DEFAULT, 'Торньяк', 1),
       (DEFAULT, 'Тоса-ину', 1),
       (DEFAULT, 'Трансильванская гончая', 1),
       (DEFAULT, 'Тувинская овчарка', 1),
       (DEFAULT, 'Уиппет', 1),
       (DEFAULT, 'Уругвайский симаррон', 1),
       (DEFAULT, 'Уэльская овчарка', 1),
       (DEFAULT, 'Фален', 1),
       (DEFAULT, 'Фараонова собака', 1),
       (DEFAULT, 'Фарфоровая гончая', 1),
       (DEFAULT, 'Филд-спаниель', 1),
       (DEFAULT, 'Финская гончая', 1),
       (DEFAULT, 'Финский лаппхунд', 1),
       (DEFAULT, 'Финский шпиц', 1),
       (DEFAULT, 'Фландрский бувье', 1),
       (DEFAULT, 'Фокстерьер', 1),
       (DEFAULT, 'Французский бульдог', 1),
       (DEFAULT, 'Французский спаниель', 1),
       (DEFAULT, 'Ханаанская собака', 1),
       (DEFAULT, 'Харьер', 1),
       (DEFAULT, 'Хеллефорсхунд', 1),
       (DEFAULT, 'Ховаварт', 1),
       (DEFAULT, 'Хоккайдо', 1),
       (DEFAULT, 'Хорватская овчарка', 1),
       (DEFAULT, 'Хортая борзая', 1),
       (DEFAULT, 'Цвергшнауцер', 1),
       (DEFAULT, 'Чау-чау', 1),
       (DEFAULT, 'Чёрно-подпалый кунхаунд', 1),
       (DEFAULT, 'Чёрный терьер', 1),
       (DEFAULT, 'Чесапик-бей-ретривер', 1),
       (DEFAULT, 'Чехословацкая волчья собака', 1),
       (DEFAULT, 'Чешская пастушья собака', 1),
       (DEFAULT, 'Чешский терьер', 1),
       (DEFAULT, 'Чинук', 1),
       (DEFAULT, 'Чирнеко дель Этна', 1),
       (DEFAULT, 'Чихуахуа', 1),
       (DEFAULT, 'Чукотская ездовая', 1),
       (DEFAULT, 'Шапендуа', 1),
       (DEFAULT, 'Шарпей', 1),
       (DEFAULT, 'Шарпланинская овчарка', 1),
       (DEFAULT, 'Шведский белый элкхунд', 1),
       (DEFAULT, 'Шведский вальхунд', 1),
       (DEFAULT, 'Шведский лаппхунд', 1),
       (DEFAULT, 'Швейцарская гончая', 1),
       (DEFAULT, 'Шелковистый виндхаунд', 1),
       (DEFAULT, 'Шелти', 1),
       (DEFAULT, 'Ши-тцу', 1),
       (DEFAULT, 'Шотландский сеттер', 1),
       (DEFAULT, 'Шотландский терьер', 1),
       (DEFAULT, 'Энтлебухер зенненхунд', 1),
       (DEFAULT, 'Эрдельтерьер', 1),
       (DEFAULT, 'Эстонская гончая', 1),
       (DEFAULT, 'Эштрельская овчарка', 1),
       (DEFAULT, 'Южнорусская овчарка', 1),
       (DEFAULT, 'Юрская гончая', 1),
       (DEFAULT, 'Якутская лайка', 1),
       (DEFAULT, 'Ямтхунд', 1),
       (DEFAULT, 'Японский терьер', 1),
       (DEFAULT, 'Японский хин', 1),
       (DEFAULT, 'Японский шпиц', 1),
       (DEFAULT, 'Абиссинская кошка', 2),
       (DEFAULT, 'Австралийская дымчатая кошка', 2),
       (DEFAULT, 'Азиатская табби', 2),
       (DEFAULT, 'Американская жесткошёрстная кошка', 2),
       (DEFAULT, 'Американская короткошёрстная кошка', 2),
       (DEFAULT, 'Американский кёрл', 2),
       (DEFAULT, 'Анатолийская кошка', 2),
       (DEFAULT, 'Ангорская кошка', 2),
       (DEFAULT, 'Аравийский мау', 2),
       (DEFAULT, 'Ашера', 2),
       (DEFAULT, 'Балинезийская кошка', 2),
       (DEFAULT, 'Бамбино', 2),
       (DEFAULT, 'Бенгальская кошка (домашняя)', 2),
       (DEFAULT, 'Бирманская кошка', 2),
       (DEFAULT, 'Бомбейская кошка', 2),
       (DEFAULT, 'Бразильская короткошёрстная кошка', 2),
       (DEFAULT, 'Британская длинношёрстная кошка', 2),
       (DEFAULT, 'Британская короткошёрстная кошка', 2),
       (DEFAULT, 'Бурма', 2),
       (DEFAULT, 'Бурмилла', 2),
       (DEFAULT, 'Гавана', 2),
       (DEFAULT, 'Гималайская кошка', 2),
       (DEFAULT, 'Двельф', 2),
       (DEFAULT, 'Девон-рекс', 2),
       (DEFAULT, 'Донской сфинкс', 2),
       (DEFAULT, 'Европейская кошка', 2),
       (DEFAULT, 'Египетский мау', 2),
       (DEFAULT, 'Йоркская шоколадная кошка', 2),
       (DEFAULT, 'Канаани', 2),
       (DEFAULT, 'Карельский бобтейл', 2),
       (DEFAULT, 'Картезианская кошка', 2),
       (DEFAULT, 'Кимрийская кошка', 2),
       (DEFAULT, 'Кинкалоу', 2),
       (DEFAULT, 'Корат', 2),
       (DEFAULT, 'Корниш-рекс', 2),
       (DEFAULT, 'Курильский бобтейл', 2),
       (DEFAULT, 'Кхао-мани', 2),
       (DEFAULT, 'Лаперм', 2),
       (DEFAULT, 'Ликой', 2),
       (DEFAULT, 'Манчкин', 2),
       (DEFAULT, 'Международная федерация кошек', 2),
       (DEFAULT, 'Мейн-кун', 2),
       (DEFAULT, 'Меконгский бобтейл', 2),
       (DEFAULT, 'Минскин', 2),
       (DEFAULT, 'Мэнкс', 2),
       (DEFAULT, 'Невская маскарадная кошка', 2),
       (DEFAULT, 'Немецкий рекс', 2),
       (DEFAULT, 'Нибелунг', 2),
       (DEFAULT, 'Норвежская лесная кошка', 2),
       (DEFAULT, 'Ориентальная кошка', 2),
       (DEFAULT, 'Оцикет', 2),
       (DEFAULT, 'Персидская кошка', 2),
       (DEFAULT, 'Пиксибоб', 2),
       (DEFAULT, 'Питерболд', 2),
       (DEFAULT, 'Рагамаффин', 2),
       (DEFAULT, 'Русская голубая кошка', 2),
       (DEFAULT, 'Рэгдолл', 2),
       (DEFAULT, 'Саванна', 2),
       (DEFAULT, 'Сейшельская кошка', 2),
       (DEFAULT, 'Селкирк-рекс', 2),
       (DEFAULT, 'Серенгети', 2),
       (DEFAULT, 'Сиамская кошка', 2),
       (DEFAULT, 'Сибирская кошка', 2),
       (DEFAULT, 'Сингапурская кошка', 2),
       (DEFAULT, 'Скиф-той-боб', 2),
       (DEFAULT, 'Сноу-шу', 2),
       (DEFAULT, 'Сококе', 2),
       (DEFAULT, 'Сомали', 2),
       (DEFAULT, 'Сфинкс', 2),
       (DEFAULT, 'Тайская кошка', 2),
       (DEFAULT, 'Тойгер', 2),
       (DEFAULT, 'Тонкинская кошка', 2),
       (DEFAULT, 'Турецкий ван', 2),
       (DEFAULT, 'Украинский левкой', 2),
       (DEFAULT, 'Уральский рекс', 2),
       (DEFAULT, 'Хауси', 2),
       (DEFAULT, 'Цейлонская кошка', 2),
       (DEFAULT, 'Шотландская вислоухая кошка', 2),
       (DEFAULT, 'Экзотическая кошка', 2),
       (DEFAULT, 'Эльф', 2),
       (DEFAULT, 'Японский бобтейл', 2);