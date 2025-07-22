// [ms]単位で時刻を取得するためのクラス
class ClockMillis
{
  // コンストラクタ（初期化関数、クラス名と同じ関数で記述すればよい）
  ClockMillis() {
    previous_second = second(); // 現在の時刻[s]の値を保存しておく
    timestamp = millis();  // 現在の時刻[ms]の値を保存しておく
  }
  
  // 時刻[ms]を取得する関数
  int get() {
    
    // もし現在時刻[s]が最後に保存された時刻[s]とことなる場合（一秒経過した場合）
    if ( second() != previous_second ) {
      previous_second = second();  // 現在の時刻[s]を保存しておく
      timestamp = millis(); // 現在の実行経過時間[ms]を保存しておく
    }
    // timestampはsecond()の値が変わるたびにそのタイミングでのmillis()を値を保存しているため、
    // millis()-timestamp を計算することで時刻[ms]を計測できる
    return (millis()-timestamp);
  }
  // クラス内で使用可能な変数（メンバ変数）の宣言
  int previous_second;
  int timestamp;
}
