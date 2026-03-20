import '../models/models.dart';

/// ============================================================================
/// DEMO DATA SERVICE
/// ============================================================================
/// Сервис с демо-данными (заглушки вместо TMDB API)
/// Постеры взяты с TMDB
/// ============================================================================

class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;
  DemoDataService._internal();

  /// Демо фильмы с реальными постерами от TMDB
  List<Movie> get demoMovies {
    return [
      Movie(
        id: 1,
        title: 'Начало',
        overview: 'Кобб — талантливый вор, лучший в опасном искусстве извлечения секретов из подсознания во время сна. Кобб получает шанс на новую жизнь, но только если совершит невозможное — не кражу, а внедрение.',
        posterPath: '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        backdropPath: '/s3TBrRGB1jav7y4argnzPkNPZKt.jpg',
        voteAverage: 8.8,
        voteCount: 35000,
        releaseDate: '2010-07-16',
        genreIds: [1, 3, 5],
        popularity: 95.5,
        tagline: 'Сон реален',
        runtime: 148,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 2,
        title: 'Интерстеллар',
        overview: 'Когда засуха и пыльные бури приводят человечество к продовольственному кризису, бывший пилот НАСА Купер отправляется в экспедицию через червоточину в поисках новой планеты, пригодной для жизни.',
        posterPath: '/gEU2QniL6C8z1tZ96789k2YzJp.jpg',
        backdropPath: '/rAiYTfKGqDCRIIqo664sY9XZIvQ.jpg',
        voteAverage: 8.6,
        voteCount: 32000,
        releaseDate: '2014-11-07',
        genreIds: [1, 2, 5],
        popularity: 92.3,
        tagline: 'Следующий шаг человечества станет величайшим',
        runtime: 169,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 3,
        title: 'Тёмный рыцарь',
        overview: 'Бэтмен поднимает ставки в войне с криминалом. С помощью лейтенанта Джима Гордона и прокурора Харви Дента он намерен очистить улицы от преступности. Но появляется новый злодей — Джокер.',
        posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        backdropPath: '/hkBaDkMWbLaf8B1lsWsKX7Znj3N.jpg',
        voteAverage: 9.0,
        voteCount: 40000,
        releaseDate: '2008-07-18',
        genreIds: [1, 3, 4],
        popularity: 98.7,
        tagline: 'Добро пожаловать в хаос',
        runtime: 152,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 4,
        title: 'Матрица',
        overview: 'Хакер Нео узнаёт, что его мир — это иллюзия, созданная машинами. Он присоединяется к восстанию против машин под руководством Морфеуса и Тринити.',
        posterPath: '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        backdropPath: '/fNG7i7RqMErkcqhohV2a6cV1Ehy.jpg',
        voteAverage: 8.7,
        voteCount: 28000,
        releaseDate: '1999-03-31',
        genreIds: [1, 3],
        popularity: 88.2,
        tagline: 'Добро пожаловать в реальный мир',
        runtime: 136,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 5,
        title: 'Побег из Шоушенка',
        overview: 'Бухгалтер Энди Дюфрейн обвинён в убийстве собственной жены и её любовника. Оказавшись в тюрьме под названием Шоушенк, он сталкивается с жестокостью и беззаконием.',
        posterPath: '/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg',
        backdropPath: '/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
        voteAverage: 9.3,
        voteCount: 45000,
        releaseDate: '1994-09-23',
        genreIds: [2, 4],
        popularity: 96.1,
        tagline: 'Страх может сделать тебя свободным',
        runtime: 142,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 6,
        title: 'Криминальное чтиво',
        overview: 'Две истории киллеров Винсента Веги и Джулса Винфилда, боксёра Бутча Кулиджа и гангстера Марселласа Уоллеса переплетаются в нескольких новеллах.',
        posterPath: '/d5iIlPs5KIABZZXsO4JgBhXfR3.jpg',
        backdropPath: '/4cDFJr4HnXN5AdPw4NDrmD6rKSE.jpg',
        voteAverage: 8.9,
        voteCount: 38000,
        releaseDate: '1994-10-14',
        genreIds: [3, 4],
        popularity: 94.5,
        tagline: 'Не просто криминал',
        runtime: 154,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 7,
        title: 'Бойцовский клуб',
        overview: 'Сотрудник страховой компании страдает хронической бессонницей и отчаянно пытается вырваться из мучительно скучной жизни. Однажды в очередной командировке он встречает некоего Тайлера Дёрдена.',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        backdropPath: '/52AfXWuXCHn3UjD17rBruA9f5qb.jpg',
        voteAverage: 8.8,
        voteCount: 36000,
        releaseDate: '1999-10-15',
        genreIds: [4],
        popularity: 91.8,
        tagline: 'Правила бойцовского клуба: никому не говорить о бойцовском клубе',
        runtime: 139,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 8,
        title: 'Властелин колец: Возвращение короля',
        overview: 'Фродо и Сэм продолжают путь к Роковой горе, чтобы уничтожить Кольцо. Арагорн готовится к последней битве за Средиземье.',
        posterPath: '/rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg',
        backdropPath: '/2u7zbn8EudG6kLlBzUYqP8RyFU4.jpg',
        voteAverage: 9.0,
        voteCount: 34000,
        releaseDate: '2003-12-17',
        genreIds: [1, 5, 6],
        popularity: 93.4,
        tagline: 'Путешествие заканчивается',
        runtime: 201,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 9,
        title: 'Форрест Гамп',
        overview: 'История простого и доброго человека с Алабамы, который благодаря своему чистому сердцу становится свидетелем и участником важнейших событий в истории США.',
        posterPath: '/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg',
        backdropPath: '/7c9UVPPiTPltouxRVXTYgHa75Hu.jpg',
        voteAverage: 8.8,
        voteCount: 33000,
        releaseDate: '1994-07-06',
        genreIds: [2, 4, 7],
        popularity: 90.2,
        tagline: 'Мир увидит его по-другому',
        runtime: 142,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 10,
        title: 'Леон',
        overview: 'Профессиональный убийца Леон живёт уединённой жизнью, пока в его жизни не появляется соседка-подросток Матильда, чья семья была убита коррумпированными полицейскими.',
        posterPath: '/yI6X2cCM5YPJtxMhUd3dPGqWdXY.jpg',
        backdropPath: '/gHJbTLnMzQXkN1aKzPnGJNqWdXY.jpg',
        voteAverage: 8.5,
        voteCount: 29000,
        releaseDate: '1994-11-18',
        genreIds: [3, 4],
        popularity: 87.6,
        tagline: 'Если хочешь работу — найми профессионала',
        runtime: 110,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 11,
        title: 'Зелёная миля',
        overview: 'В тюрьме «Холодная гора» работает охранник Пол Эджкомб. Однажды в камеру смертников привозят нового заключённого — чернокожего великана по имени Джон Коффи.',
        posterPath: '/velWPhVMQeQKcxggNEU8YmIo52R.jpg',
        backdropPath: '/l6hQAA9UFP6cILq4kGQjRfKzJp.jpg',
        voteAverage: 8.6,
        voteCount: 31000,
        releaseDate: '1999-12-10',
        genreIds: [2, 4, 8],
        popularity: 89.3,
        tagline: 'Чудеса случаются',
        runtime: 189,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
      Movie(
        id: 12,
        title: 'Гладиатор',
        overview: 'Римский генерал Максимус предан новым императором Коммодом и продан в рабство. Став гладиатором, он стремится отомстить за гибель семьи.',
        posterPath: '/ty8TGRuvJLPUmAR1H1nRIsgwvim.jpg',
        backdropPath: '/6wkfovpn7Eq8dYNKaG5PY3q2oq6.jpg',
        voteAverage: 8.5,
        voteCount: 27000,
        releaseDate: '2000-05-05',
        genreIds: [1, 2, 6],
        popularity: 86.9,
        tagline: 'Что мы делаем в жизни, отзывается эхом в вечности',
        runtime: 155,
        status: 'Вышел',
        originalLanguage: 'en',
      ),
    ];
  }

  /// Демо жанры
  List<Genre> get demoGenres {
    return [
      Genre(id: 1, name: 'Фантастика'),
      Genre(id: 2, name: 'Драма'),
      Genre(id: 3, name: 'Боевик'),
      Genre(id: 4, name: 'Триллер'),
      Genre(id: 5, name: 'Приключения'),
      Genre(id: 6, name: 'Фэнтези'),
      Genre(id: 7, name: 'Мелодрама'),
      Genre(id: 8, name: 'История'),
    ];
  }

  /// Получить тренды (топ по популярности)
  List<Movie> getTrendingMovies() {
    final sorted = List<Movie>.from(demoMovies);
    sorted.sort((a, b) => b.popularity!.compareTo(a.popularity!));
    return sorted;
  }

  /// Получить популярные
  List<Movie> getPopularMovies() {
    final sorted = List<Movie>.from(demoMovies);
    sorted.sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return sorted.take(8).toList();
  }

  /// Получить топ rated
  List<Movie> getTopRatedMovies() {
    final sorted = List<Movie>.from(demoMovies);
    sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    return sorted;
  }

  /// Поиск фильмов
  List<Movie> searchMovies(String query) {
    final lowerQuery = query.toLowerCase();
    return demoMovies.where((movie) {
      return movie.title.toLowerCase().contains(lowerQuery) ||
          movie.overview!.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Фильмы по жанру
  List<Movie> getMoviesByGenre(int genreId) {
    return demoMovies.where((movie) {
      return movie.genreIds.contains(genreId);
    }).toList();
  }

  /// Получить жанр по ID
  Genre? getGenreById(int id) {
    try {
      return demoGenres.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}
