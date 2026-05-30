// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appName => 'YBS လမ်းညွှန်';

  @override
  String get appNameBurmese => 'ရန်ကုန်ဘတ်စ်ကားလမ်းညွှန်';

  @override
  String get home => 'ရှေ့မှာ';

  @override
  String get search => 'ရှာဖွေမည်';

  @override
  String get map => 'မြေပုံ';

  @override
  String get favorites => 'သိမ်းထားသည်';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get tripPlanner => 'ခရီးစဉ်ရှာဖွေမည်';

  @override
  String get routeNotFound => 'လမ်းကြောင်း မတွေ့ပါ';

  @override
  String get retry => 'ထပ်ကြိုးစားမည်';

  @override
  String get networkErrorTitle => 'ကွန်ရက်ချိတ်ဆက်မှု ပြဿနာ';

  @override
  String get networkErrorMessage =>
      'အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ။';

  @override
  String get loading => 'တင်နေသည်';

  @override
  String get searchHint => 'လမ်းကြောင်း၊ မှတ်တိုင် သို့မဟုတ် ဦးတည်ရာ ရှာဖွေမည်';

  @override
  String get clear => 'ရှင်းမည်';

  @override
  String get all => 'အားလုံး';

  @override
  String get airConOnly => 'အဲကွန်းသာ';

  @override
  String get regular => 'ရိုးရိုး';

  @override
  String get recentSearches => 'လတ်တလော ရှာဖွေမှုများ';

  @override
  String get noSearchResults =>
      'ရှာဖွေမှုနှင့် ကိုက်ညီသော YBS လမ်းကြောင်း မတွေ့ပါ။';

  @override
  String get tryDifferentSearch =>
      'လမ်းကြောင်းနံပါတ်၊ မှတ်တိုင်အမည် သို့မဟုတ် ဦးတည်ရာဖြင့် ထပ်ရှာပါ။';

  @override
  String fareKyat(String fare) {
    return '$fare ကျပ်';
  }

  @override
  String get noFavorites => 'သိမ်းထားသည့်လမ်းကြောင်းမရှိသေးပါ';

  @override
  String get removedFromFavorites => 'သိမ်းထားသည်မှ ဖယ်ရှားပြီးပါပြီ';

  @override
  String get undo => 'ပြန်ယူမည်';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get theme => 'အရောင်စနစ်';

  @override
  String get english => 'English';

  @override
  String get myanmar => 'မြန်မာ';

  @override
  String get light => 'အလင်း';

  @override
  String get dark => 'အမှောင်';

  @override
  String get system => 'စနစ်အတိုင်း';

  @override
  String get clearCache => 'Cache ဖျက်မည်';

  @override
  String get clearCacheDescription => 'ယာယီသိမ်းထားသော အချက်အလက်များ ဖျက်မည်';

  @override
  String get cacheCleared => 'Cache ဖျက်ပြီးပါပြီ';

  @override
  String get versionLoading => 'ဗားရှင်း တင်နေသည်...';

  @override
  String get findRoutes => 'လမ်းကြောင်းရှာမည်';

  @override
  String get fromStop => 'စမှတ်';

  @override
  String get toStop => 'သွားမည့်မှတ်တိုင်';

  @override
  String get noTripResults => 'လမ်းကြောင်းရလဒ် မရှိသေးပါ';

  @override
  String get directRoute => 'တိုက်ရိုက်လမ်းကြောင်း';

  @override
  String get transferRoute => 'ပြောင်းစီးလမ်းကြောင်း';

  @override
  String changeAt(String stop) {
    return '$stop တွင် ပြောင်းစီးပါ';
  }

  @override
  String stopsCount(int count) {
    return '$count မှတ်တိုင်';
  }
}
