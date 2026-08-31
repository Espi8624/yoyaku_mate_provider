# スタッフ勤務可能時間の入力・管理 (Staff Availability)

> 最終更新: 2026-08-30  
> 関連ファイル: [`lib/pages/profile_page/widgets/views/personal_profile_view.dart`](../../lib/pages/profile_page/widgets/views/personal_profile_view.dart), [`lib/pages/profile_page/dialogs/availability_dialog.dart`](../../lib/pages/profile_page/dialogs/availability_dialog.dart), [`lib/pages/profile_page/dialogs/day_availability_dialog.dart`](../../lib/pages/profile_page/dialogs/day_availability_dialog.dart), [`lib/pages/staff_management_page/widgets/staff_management_view.dart`](../../lib/pages/staff_management_page/widgets/staff_management_view.dart)

## 概要

将来の「ボタン一つでのシフト表自動生成」機能の土台として、スタッフ本人が曜日ごとに勤務可能な時間帯(午前・午後)を入力し、店舗マネージャーがスタッフ管理画面からそれを曜日単位で照会・修正できる機能です。

---

## 1. 本人による入力 (個人プロフィール画面)

役職 (管理者/職員) に関係なく、全ユーザー共通の「一般」プロフィールタブに「勤務情報」セクションが表示されます。

* 「勤務可能時間」項目をタップすると、7曜日すべてをまとめて設定できる `AvailabilityDialog` が開きます。
* 各曜日ごとに `午前` / `午後` を `ChoiceChip` で複数選択でき、選択がない曜日は勤務不可として扱われます。
* 保存すると `PATCH /api/stores/{storeId}/staff/me/availability` が呼び出されます。

---

## 2. マネージャーによる照会・修正 (スタッフ管理画面)

スタッフ管理画面の各スタッフカードに、「権限設定」とは独立して開閉できる「勤務可能日」セクションがあります。

* タップして展開すると、月〜日の7曜日が円形バッジ (56×56) で表示されます。
* **勤務可能な曜日は強調色、不可の曜日はグレー**で視覚的に区別されます。
* バッジ1つ1つが独立したボタンになっており、**特定の曜日のバッジをタップすると、その曜日1日分だけの時間帯を編集する軽量ダイアログ (`DayAvailabilityDialog`)** が開きます。7曜日すべてを一度に編集する必要はありません。
* 確定すると、タップした曜日以外の既存の値を維持したまま `PATCH /api/stores/{storeId}/staff/{staffId}/availability` が呼び出されます。

---

## 3. UI設計のポイント

* 曜日バッジは片手操作でも押しやすいよう、44px以上のタップ領域を確保する形で56×56に設定しています。
* 「勤務可能日」は「権限設定」ドロップダウンの内側ではなく、独立した開閉セクションとして配置されており、権限設定を開かなくても勤務可能日だけを個別に開閉できます。

→ 実装の詳細は [実装詳細書: スタッフ勤務可能時間](../implementation/staff-availability.md) を参照。
