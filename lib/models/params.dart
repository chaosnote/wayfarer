class AppParams {
  // 電池低電量警告門檻，預設為 30%
  // 將此數值獨立出來，方便未來其它頁面或全域邏輯共用
  static int batteryAlertLimit = 30;
  // 間隔多少分鐘驗證
  static const int batteryDurationCheck = 5;
  // 電量通知訊息圖示
  static const String batteryIconNotification = "ic_notification";
}
