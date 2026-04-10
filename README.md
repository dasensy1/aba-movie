# Movie Tracker - Flutter Application

Локальное мобильное приложение для отслеживания фильмов с поддержкой OMDb API.

Все пользовательские данные хранятся локально на устройстве в SQLite.

---

## Содержание

- [Возможности](#возможности)
- [Архитектура базы данных](#архитектура-базы-данных)
- [Технологии](#технологии)
- [Структура проекта](#структура-проекта)
- [Установка и запуск](#установка-и-запуск)

---

## Возможности

### Фильмы
- Просмотр трендовых фильмов (OMDb API)
- Популярные фильмы
- Фильмы с высоким рейтингом
- Детальная информация о фильме (OMDb API)
- 12 демо-фильмов встроенных в приложение

### Поиск
- Живой поиск с задержкой (debounce)
- Поиск по названию и описанию
- Сетка результатов

### Категории
- 8 жанров фильмов
- Фильтрация по жанрам
- Просмотр фильмов выбранного жанра

### Избранное
- Добавление/удаление фильмов
- Локальное хранение в SQLite с привязкой к пользователю
- Статистика избранных фильмов

### Трекинг просмотров
- Статусы: "Хочу посмотреть", "Смотрю", "Просмотрено", "Бросил"
- Пользовательские оценки (0-10)
- Заметки к фильмам
- Дата просмотра
- Счётчик повторных просмотров
- Лог активности

### Обзоры
- Написание отзывов к фильмам
- Рейтинги и комментарии
- Привязка к пользователю

### Авторизация
- Локальная регистрация (Email/Password)
- Вход в аккаунт
- Данные пользователей хранятся в SQLite
- Сохранение сессии

### Настройки
- Переключение темы (тёмная/светлая)
- Выбор языка
- Настройки привязаны к пользователю в БД

### UI/UX
- Glassmorphism элементы (стеклянные карточки, панели)
- Градиентные фоны и кнопки (purple-cyan, pink-purple)
- Анимированный Splash Screen с масштабированием и пульсацией
- SliverAppBar с floating/snap поведением
- Hero-баннеры с PageView и параллакс-эффектом
- Скелетоны загрузки (Shimmer effect) для всех экранов
- Кэширование изображений (CachedNetworkImage)
- Floating SnackBar уведомления
- Анимации переходов между экранами (scale, fade, slide)
- Кастомные тени с glow-эффектом (purpleGlow, cyanGlow)
- Семантические цвета (success, warning, error, info)
- Адаптивная тёмная и светлая темы
- Bottom Navigation Bar с 8 вкладками (TabStyle.reactCircle)
- Модальные нижние панели (bottom sheets) для фильтров и настроек

---

## Архитектура базы данных

Приложение использует SQLite (sqflite) версии 6 с полноценной схемой данных.

### Таблицы

**users** -- локальные пользователи
- id, email (UNIQUE), password_hash, display_name, photo_url, created_at, is_anonymous

**user_settings** -- настройки пользователя
- user_id (PK -> users), dark_theme, language

**favorites** -- избранные фильмы
- id, user_id -> users, movie_id, данные фильма, added_at
- UNIQUE(user_id, movie_id)
- Индексы: idx_favorites_user, idx_favorites_movie

**watchlist** -- список просмотра
- id, user_id -> users, movie_id, imdb_id, title, poster_path, status, user_rating, notes, watched_date, added_date, watch_count
- UNIQUE(user_id, movie_id)
- Индексы: idx_watchlist_user, idx_watchlist_movie, idx_watchlist_status

**watch_log** -- лог просмотров
- id, user_id -> users, movie_id, status, watch_date
- Индексы: idx_watch_log_user, idx_watch_log_date

**reviews** -- обзоры
- id, user_id -> users, movie_id, user_name, rating, comment, created_at
- Индексы: idx_reviews_user, idx_reviews_movie

**settings** -- общие настройки приложения (не привязаны к пользователю)
- key (PK), value

**history** -- история просмотров (legacy)
- id, title, poster_path, viewed_at и другие поля

### Хранение данных

| Источник | Что хранится |
|----------|-------------|
| SQLite (sqflite) | Пользователи, настройки пользователя, избранное, watchlist, лог просмотров, обзоры, общие настройки |
| SharedPreferences | session_user_id (восстановление сессии), first_launch, last_search |

### Миграции

При обновлении с версии 5 на 6 данные автоматически переносятся:
- Все существующие данные присваиваются пользователю с id = 1
- Настройки из таблицы settings переносятся в user_settings
- Создаются индексы и FOREIGN KEY ограничения

---

## Технологии

| Категория | Технологии |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | Provider |
| Local Storage | SQLite (sqflite), SharedPreferences |
| UI Components | convex_bottom_bar, google_fonts, shimmer, cached_network_image |
| Rating | flutter_rating_bar |

---

## Структура проекта

```
lib/
├── main.dart                 # Точка входа
├── models/                   # Модели данных
│   ├── movie.dart           # Модель фильма
│   ├── genre.dart           # Модель жанра
│   ├── app_user.dart        # Модель пользователя (для UI)
│   ├── local_user.dart      # Модель пользователя (для БД)
│   ├── watchlist_movie.dart # Модель фильма в watchlist
│   ├── review.dart          # Модель обзора
│   └── models.dart          # Экспорт моделей
├── services/                 # Сервисный слой
│   ├── omdb_api_service.dart    # OMDb API
│   ├── demo_data_service.dart   # Демо-данные
│   ├── local_database_service.dart # SQLite (v6)
│   ├── shared_prefs_service.dart   # SharedPreferences
│   └── services.dart        # Экспорт сервисов
├── repositories/             # Репозиторийный слой
│   ├── user_repository.dart # Работа с пользователями
│   └── repositories.dart    # Экспорт репозиториев
├── providers/                # State Management
│   ├── auth_provider.dart   # Состояние авторизации (БД)
│   ├── movies_provider.dart # Состояние фильмов
│   ├── favorites_provider.dart # Состояние избранного (user-scoped)
│   ├── watchlist_provider.dart # Трекинг фильмов (user-scoped)
│   ├── reviews_provider.dart # Обзоры (user-scoped)
│   ├── settings_provider.dart # Настройки (user-scoped из БД)
│   └── providers.dart       # Экспорт провайдеров
├── screens/                  # Экраны приложения
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── categories/
│   │   └── categories_screen.dart
│   ├── watchlist/
│   │   └── watchlist_screen.dart
│   ├── favorites/
│   │   └── favorites_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── about/
│   │   └── about_screen.dart
│   ├── widgets/
│   │   ├── status_rating_widget.dart
│   │   └── reviews_widget.dart
│   ├── main_screen.dart     # Главный экран с навигацией
│   └── movie_detail_screen.dart # Детали фильма
├── widgets/                  # Переиспользуемые виджеты
│   ├── common_widgets.dart  # Общие виджеты
│   ├── movie_card.dart      # Карточка фильма
│   └── widgets.dart         # Экспорт виджетов
└── utils/
    └── config.dart          # Конфигурация приложения
```

---

## Установка и запуск

### 1. Установить зависимости

```bash
cd aba-movie
flutter pub get
```

### 2. Запустить приложение

```bash
flutter run
```

### 3. Сборка релизной версии

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## Вкладки приложения

| N | Вкладка | Описание |
|---|---------|----------|
| 1 | Главная | Тренды, популярное, лучшее |
| 2 | Поиск | Поиск фильмов по названию |
| 3 | Категории | Жанры фильмов |
| 4 | Трекинг | Список просмотра со статусами |
| 5 | Избранное | Сохранённые фильмы |
| 6 | Профиль | Информация об аккаунте и статистика |
| 7 | Настройки | Тема, язык |
| 8 | О приложении | Информация |

---

## Дизайн

Приложение использует современный UI с продвинутой системой дизайна.

### Цветовая палитра

| Цвет | Значение | Назначение |
|------|----------|------------|
| Primary Purple | #8B5CF6 | Основной акцент, кнопки, индикаторы |
| Purple Dark | #7C3AED | Градиенты, активные элементы |
| Purple Light | #A78BFA | Фоновые акценты |
| Accent Cyan | #06B6D4 | Вторичный акцент |
| Accent Pink | #EC4899 | Избранное, регистрация |
| Surface Dark | #1E1B2E | Фон карточек |
| Surface Higher | #262340 | Повышенный уровень поверхности |
| Background Dark | #0F0D1A | Основной фон приложения |

### Семантические цвета

- Success: #10B981 (зелёный)
- Warning: #F59E0B (жёлтый)
- Error: #EF4444 (красный)
- Info: #3B82F6 (синий)

### Градиенты

- Primary: purple -> cyan
- Hero: purpleDark -> purple -> cyan (3-цветный)
- Sunset: pink -> purple
- Ocean: cyan -> info
- Background: radial (surfaceDarkHigher -> backgroundDark)
- Button: purple -> purpleDark
- Card Hover: surfaceDarkHigher -> surfaceDark

### Тени и свечение

- Soft shadow: alpha 0.08, blur 20
- Medium shadow: alpha 0.12, blur 24
- Purple Glow: цветная тень с spread для кнопок и логотипа
- Cyan Glow: аналогично для акцентных элементов
- FAB shadow: для плавающих кнопок

### Радиусы скругления

- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- full: 9999px (круглые элементы)

### Компоненты интерфейса

**Карточки фильмов:**
- Ширина 150px, соотношение постера 2:3
- Scale-анимация при нажатии (1.0 -> 0.95)
- Круглая кнопка избранного в углу
- Цветовой индикатор рейтинга (зелёный >= 7, жёлтый >= 5, красный < 5)

**Hero-баннер:**
- PageView с viewportFraction 0.88
- Backdrop-изображение с многослойным градиентом
- Badge тренда с gradient overlay
- Название: 24px, FontWeight.w800

**Поля ввода:**
- Полупрозрачный фон (white alpha 0.06)
- Скругление 16px
- Фиолетовая обводка при фокусе (2px)

**Экран авторизации:**
- Fade + Slide анимации появления (1200ms)
- Декоративные круги с radial gradient
- Логотип с glow-эффектом (140x140)

**Splash Screen:**
- Scale анимация с Curves.easeOutBack
- Размытые декоративные круги (cyan, pink)
- Пульсирующий ореол вокруг логотипа

**Навигация:**
- ConvexAppBar с TabStyle.reactCircle
- 8 вкладок с иконками Material Icons
- IndexedStack для сохранения состояния вкладок

**Модальные панели:**
- Bottom sheets для фильтров, статусов, выбора языка
- Glassmorphism стилизация
- Закруглённые углы

---

## Демо-данные

В приложение встроены 12 популярных фильмов:

1. Начало (Inception)
2. Интерстеллар
3. Тёмный рыцарь
4. Матрица
5. Побег из Шоушенка
6. Криминальное чтиво
7. Бойцовский клуб
8. Властелин колец: Возвращение короля
9. Форрест Гамп
10. Леон
11. Зелёная миля
12. Гладиатор

Жанры: Фантастика, Драма, Боевик, Триллер, Приключения, Фэнтези, Мелодрама, История

---

## Решение проблем

### Ошибка при запуске

```bash
flutter clean
flutter pub get
flutter run
```

### Ошибка кэша

Очистите кэш в настройках приложения.

### Ошибка базы данных

Приложение автоматически создаёт базу данных при первом запуске.
При миграции со старой версии данные переносятся автоматически.

---

## Лицензия

Данный проект создан в образовательных целях.

---

Made with Flutter
