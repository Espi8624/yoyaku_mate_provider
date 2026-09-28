// 店舗業種タグ。サーバー側 models.IsValidStoreCategory (yoyaku_mate_server) と
// 対応する固定5値。店舗登録ウィザードと設定画面(業種編集)で共有する。
enum StoreCategory {
  restaurant('RESTAURANT', '飲食店'),
  cafeDessert('CAFE_DESSERT', 'カフェ・デザート'),
  beauty('BEAUTY', '美容室・ビューティー'),
  retail('RETAIL', '小売業'),
  other('OTHER', 'その他');

  final String value; // サーバーに送信するワイヤー値 (business_category)
  final String label; // 画面表示用ラベル

  const StoreCategory(this.value, this.label);

  static StoreCategory? fromValue(String? value) {
    for (final category in StoreCategory.values) {
      if (category.value == value) return category;
    }
    return null;
  }
}
