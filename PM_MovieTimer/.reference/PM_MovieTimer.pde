import processing.video.*;

//動画の再生・停止・一時停止の変数
int r = 0;
int p = 0;
int s = 0;
int t = 0;

//開始時刻
int trg_h = 21;
int trg_m = 21;
int trg_s =00;
int trg_ms = 0; //0から999までの数字を入れる

//動画の変数
Movie mv;

//class呼び出し
ClockMillis clock_millis;

void setup() {
  fullScreen();
  //size(400, 400);
  background(0);
  noStroke();
  noCursor();

  //動画を読み込む
  mv = new Movie(this, "right_4.mp4");  //動画ファイルの名前変更場所はここ

  //millis
  clock_millis = new ClockMillis();
} 

void draw() {
  //現在時刻
  int crt_h = hour();
  int crt_m = minute();
  int crt_s = second();
  int crt_ms = clock_millis.get();


  //現在時刻と開始時刻の差分
  int dif_h = trg_h - crt_h;
  int dif_m = trg_m - crt_m;
  int dif_s = trg_s - crt_s;
  int dif_ms = trg_ms - crt_ms;

  //動画のロード
  if (mv.available()) {
    mv.read();
  }

  if (keyPressed) {
    if (key == 'r') {
      r = 1;
      p = 0;
      s = 0;
      println(r, p, s, trg_h, trg_m, trg_s, trg_ms);
    }
    if (key == 'p') {
      r = 0;
      p = 1;
      s = 0;
      println(r, p, s, trg_h, trg_m, trg_s, trg_ms);
    }
    if (key == 's') {
      r = 0;
      p = 0;
      s = 1;
      println(r, p, s, trg_h, trg_m, trg_s, trg_ms);
    }
  }

  //変数の判定
  if (dif_h <= 0 && dif_m <= 0 && dif_s <= 0 && dif_ms <= 0) {    //動画時刻再生
    t = 1;   
  }

  if (t == 1) {    //動画再生
    mv.play();
    image(mv, 0, 0, width, height);
    
    if (r == 1) {    //動画再生
      mv.play();
      image(mv, 0, 0, width, height);
    }
    if (p == 1) {    //動画一時停止
      mv.pause();
      image(mv, 0, 0, width, height);
    }
    if (s == 1) {    //動画停止
      mv.stop();
      background(0);
    }
  }
}
