import processing.video.*;
import g4p_controls.*;

//動画の再生・停止・一時停止の変数
int r = 0;
int p = 0;
int s = 0;
int t = 0;

//画面モード（0:設定画面, 1:実行画面）
int screenMode = 0;
boolean isSettingsWindow = true;
PApplet executionWindow;

//複数タイマー用
class TimerData {
  int hour, minute, second, millisecond;
  String videoFile;
  String name;
  boolean enabled;
  boolean hasPlayed;  // 一度再生されたかどうか
  
  TimerData(String n, int h, int m, int s, int ms, String video) {
    name = n;
    hour = h;
    minute = m;
    second = s;
    millisecond = ms;
    videoFile = video;
    enabled = true;
    hasPlayed = false;
  }
  
  void reset() {
    hasPlayed = false;
  }
}

ArrayList<TimerData> timerList = new ArrayList<TimerData>();
int currentTimerIndex = -1;
boolean videoFinished = false;

//開始時刻（メイン用）
int trg_h = 19;
int trg_m = 19;
int trg_s = 0;
int trg_ms = 0;

//動画の変数
Movie mv;

//GUI要素 - 基本
GTextField tfHour, tfMinute, tfSecond, tfName, tfVideoFile;
GButton btnAdd, btnDelete, btnStart, btnSettings, btnReset, btnOpenExecutionWindow;
GDropList timerListGUI, displaySelectGUI;
GLabel lblStatus, lblCurrentTime, lblDisplaySelect;

//GUI要素 - 動的タイマー用
ArrayList<GTextField> timerHourFields = new ArrayList<GTextField>();
ArrayList<GTextField> timerMinuteFields = new ArrayList<GTextField>();
ArrayList<GTextField> timerSecondFields = new ArrayList<GTextField>();
ArrayList<GTextField> timerNameFields = new ArrayList<GTextField>();
ArrayList<GTextField> timerVideoFields = new ArrayList<GTextField>();
ArrayList<GCheckbox> timerEnabledBoxes = new ArrayList<GCheckbox>();

int maxTimers = 5;
boolean useMultipleTimerUI = false;

//class呼び出し
ClockMillis clock_millis;

void setup() {
  size(800, 600); // 設定画面のサイズ
  background(240);
  
  // デフォルトのタイマーを追加
  timerList.add(new TimerData("Timer1", 19, 25, 0, 0, "rabbit.mp4"));
  
  createGUI();
  
  //millis
  clock_millis = new ClockMillis();
}

void createGUI() {
  // 基本的なGUI要素を作成
  tfName = new GTextField(this, 50, 50, 200, 25);
  tfName.setText("Timer Name");
  
  tfHour = new GTextField(this, 50, 90, 60, 25);
  tfHour.setText("19");
  
  tfMinute = new GTextField(this, 120, 90, 60, 25);
  tfMinute.setText("25");
  
  tfSecond = new GTextField(this, 190, 90, 60, 25);
  tfSecond.setText("0");
  
  tfVideoFile = new GTextField(this, 50, 130, 200, 25);
  tfVideoFile.setText("rabbit.mp4");
  
  btnAdd = new GButton(this, 270, 90, 60, 25, "Add");
  btnDelete = new GButton(this, 270, 130, 60, 25, "Delete");
  btnReset = new GButton(this, 350, 90, 80, 25, "Reset All");
  btnStart = new GButton(this, 50, 170, 120, 30, "Start Monitoring");
  btnSettings = new GButton(this, 180, 170, 120, 30, "Multi Timer UI");
  btnOpenExecutionWindow = new GButton(this, 310, 170, 150, 30, "Open Execution Window");
  
  // ディスプレイ選択
  lblDisplaySelect = new GLabel(this, 50, 210, 100, 25);
  lblDisplaySelect.setText("Display:");
  displaySelectGUI = new GDropList(this, 150, 210, 200, 120, 3);
  displaySelectGUI.setItems(new String[]{"Primary Display", "Secondary Display", "Custom Window"}, 0);
  
  timerListGUI = new GDropList(this, 50, 250, 400, 120, 5);
  
  lblStatus = new GLabel(this, 50, 380, 400, 30);
  lblStatus.setText("Status: Ready");
  
  lblCurrentTime = new GLabel(this, 500, 30, 200, 30);
  
  updateTimerList();
  createMultipleTimerUI();
}

void createMultipleTimerUI() {
  // 複数タイマー用のUI要素を作成
  for (int i = 0; i < maxTimers; i++) {
    int yPos = 420 + i * 35;
    
    GTextField hourField = new GTextField(this, 50, yPos, 50, 25);
    GTextField minuteField = new GTextField(this, 110, yPos, 50, 25);
    GTextField secondField = new GTextField(this, 170, yPos, 50, 25);
    GTextField nameField = new GTextField(this, 230, yPos, 120, 25);
    GTextField videoField = new GTextField(this, 360, yPos, 120, 25);
    GCheckbox enabledBox = new GCheckbox(this, 490, yPos, 80, 25, "Enabled");
    
    hourField.setText("00");
    minuteField.setText("00");
    secondField.setText("00");
    nameField.setText("Timer" + (i+1));
    videoField.setText("rabbit.mp4");
    enabledBox.setSelected(false);
    
    // 初期状態では非表示
    hourField.setVisible(false);
    minuteField.setVisible(false);
    secondField.setVisible(false);
    nameField.setVisible(false);
    videoField.setVisible(false);
    enabledBox.setVisible(false);
    
    timerHourFields.add(hourField);
    timerMinuteFields.add(minuteField);
    timerSecondFields.add(secondField);
    timerNameFields.add(nameField);
    timerVideoFields.add(videoField);
    timerEnabledBoxes.add(enabledBox);
  }
} 

void draw() {
  background(240);
  
  // 現在時刻の更新
  lblCurrentTime.setText("Current: " + nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2));
  
  if (isSettingsWindow) {
    drawSettingsScreen();
  }
  
  // タイマー監視が開始されていれば実行
  if (screenMode == 1) {
    monitorTimers();
  }
}

void drawSettingsScreen() {
  fill(0);
  textSize(18);
  text("Timer Settings", 50, 30);
  
  textSize(12);
  text("Name:", 50, 45);
  text("Hour:", 50, 85);
  text("Min:", 120, 85);
  text("Sec:", 190, 85);
  text("Video File:", 50, 125);
  
  // 複数タイマーUIが有効な場合の表示
  if (useMultipleTimerUI) {
    text("Multiple Timer Configuration:", 50, 405);
    text("H", 65, 415);
    text("M", 125, 415);
    text("S", 185, 415);
    text("Name", 260, 415);
    text("Video File", 400, 415);
  }
}

void monitorTimers() {
  int crt_h = hour();
  int crt_m = minute();
  int crt_s = second();
  int crt_ms = clock_millis.get();

  checkActiveTimer(crt_h, crt_m, crt_s, crt_ms);
}

void checkActiveTimer(int crt_h, int crt_m, int crt_s, int crt_ms) {
  for (int i = 0; i < timerList.size(); i++) {
    TimerData timer = timerList.get(i);
    if (!timer.enabled || timer.hasPlayed) continue;
    
    // 時刻の差分計算
    int dif_h = timer.hour - crt_h;
    int dif_m = timer.minute - crt_m;
    int dif_s = timer.second - crt_s;
    int dif_ms = timer.millisecond - crt_ms;
    
    // タイマー時刻に到達した場合
    if (dif_h <= 0 && dif_m <= 0 && dif_s <= 0 && dif_ms <= 0) {
      currentTimerIndex = i;
      timer.hasPlayed = true; // 一度再生したことをマーク
      openExecutionWindow(timer);
      lblStatus.setText("Timer activated: " + timer.name);
      println("Timer activated: " + timer.name);
      break;
    }
  }
}

void openExecutionWindow(TimerData timer) {
  // 1. 動画ファイルの絶対パスを取得する
  String validPath = "";
  java.io.File videoFile = new java.io.File(sketchPath("data/" + timer.videoFile));

  if (videoFile.exists()) {
    validPath = videoFile.getAbsolutePath();
    println("Video file found at (absolute path): " + validPath);
  } else {
    // ファイルが見つからなかった場合はウィンドウを開かずに終了する
    println("Error: Video file not found at " + videoFile.getPath());
    lblStatus.setText("Error: Video file not found - " + timer.videoFile);
    return;
  }

  // 2. 実行ウィンドウを開き、取得した絶対パス(validPath)を渡す
  int displayMode = displaySelectGUI.getSelectedIndex();

  if (displayMode == 0) {
    // プライマリディスプレイ
    executionWindow = new ExecutionWindow(timer, validPath, 0, 0, displayWidth, displayHeight, true);
  } else if (displayMode == 1) {
    // セカンダリディスプレイ
    executionWindow = new ExecutionWindow(timer, validPath, displayWidth, 0, displayWidth, displayHeight, true);
  } else {
    // カスタムウィンドウ
    executionWindow = new ExecutionWindow(timer, validPath, 100, 100, 800, 600, false);
  }
}
// 実行ウィンドウクラス
// 実行ウィンドウクラス
class ExecutionWindow extends PApplet {
  TimerData currentTimer;
  String videoAbsolutePath; // 動画の絶対パスを保持する変数
  Movie movie;
  ClockMillis clockMillis;
  boolean isFullscreen;
  int windowX, windowY, windowWidth, windowHeight;
  boolean videoStarted = false;
  
  // コンストラクタで文字列のパス(absPath)を受け取れるように変更
  ExecutionWindow(TimerData timer, String absPath, int x, int y, int w, int h, boolean fullscreen) {
    super();
    currentTimer = timer;
    videoAbsolutePath = absPath; // 渡された絶対パスを保存
    windowX = x;
    windowY = y;
    windowWidth = w;
    windowHeight = h;
    isFullscreen = fullscreen;
    
    PApplet.runSketch(new String[]{this.getClass().getSimpleName()}, this);
  }
  
  public void settings() {
    if (isFullscreen) {
      fullScreen();
      // フルスクリーンの場合、特定のディスプレイを指定
      if (windowX > 0) {
        fullScreen(2); // セカンダリディスプレイ
      } else {
        fullScreen(1); // プライマリディスプレイ
      }
    } else {
      size(windowWidth, windowHeight);
    }
  }
  
  public void setup() {
    surface.setLocation(windowX, windowY);
    background(0);
    
    try {
      // 保存しておいた絶対パスで動画を読み込む
      println("Attempting to load video from absolute path: " + videoAbsolutePath);
      movie = new Movie(this, videoAbsolutePath);
      
      clockMillis = new ClockMillis();
      println("Execution window opened for: " + currentTimer.name);
      println("Video loaded successfully: " + currentTimer.videoFile);
    } catch (Exception e) {
      println("Error loading video: " + currentTimer.videoFile);
      println("Error: " + e.getMessage());
      e.printStackTrace();
      // デフォルトでテスト映像を作成
      movie = null;
    }
  }
  
  // 以降の draw(), movieEvent(), exit() メソッドは元のままでOKです
  public void draw() {
    background(0);
    
    if (movie == null) {
      // 動画が読み込めなかった場合のテスト表示
      fill(255, 0, 0);
      textAlign(CENTER, CENTER);
      textSize(32);
      text("VIDEO NOT FOUND", width/2, height/2);
      text(currentTimer.videoFile, width/2, height/2 + 50);
      fill(255);
      textSize(16);
      text("Press ESC or C to close", width/2, height/2 + 100);
      return;
    }
    
    if (!videoStarted) {
      movie.play();
      videoStarted = true;
    }
    
    if (movie.available()) {
      movie.read();
    }
    
    // 動画を表示
    if (videoStarted && movie.width > 0 && movie.height > 0) {
      // アスペクト比を保持して全画面表示
      float movieAspect = (float)movie.width / (float)movie.height;
      float screenAspect = (float)width / (float)height;
      
      int drawWidth, drawHeight;
      int drawX, drawY;
      
      if (movieAspect > screenAspect) {
        // 動画が横長の場合、幅を基準にする
        drawWidth = width;
        drawHeight = (int)(width / movieAspect);
        drawX = 0;
        drawY = (height - drawHeight) / 2;
      } else {
        // 動画が縦長の場合、高さを基準にする
        drawWidth = (int)(height * movieAspect);
        drawHeight = height;
        drawX = (width - drawWidth) / 2;
        drawY = 0;
      }
      
      // 動画を中央に配置して表示
      image(movie, drawX, drawY, drawWidth, drawHeight);
      
      // デバッグ情報を左上に表示（小さく）
      fill(255, 255, 0);
      textAlign(LEFT, TOP);
      textSize(12);
      text("Video: " + movie.width + "x" + movie.height, 10, 10);
      text("Time: " + nf(movie.time(), 1, 1) + "/" + nf(movie.duration(), 1, 1), 10, 25);
      
      // 動画が終了したかチェック
      if (movie.time() >= movie.duration() - 0.1) { // 少し余裕を持たせる
        background(0); // 黒い画面に戻す
        movie.stop();
        
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(24);
        text("Video Finished", width/2, height/2);
        textSize(16);
        text("Window will close in 3 seconds", width/2, height/2 + 40);
        
        // 3秒後にウィンドウを閉じる
        if (millis() > (movie.duration() * 1000 + 3000)) {
          exit();
        }
      }
    } else if (videoStarted) {
      // 動画が読み込まれていない場合の情報表示
      fill(255, 255, 0);
      textAlign(CENTER, CENTER);
      textSize(16);
      text("Loading video...", width/2, height/2);
      if (movie != null) {
        text("Video dimensions: " + movie.width + "x" + movie.height, width/2, height/2 + 30);
      }
    }
    
    // ESCキーで終了
    if (keyPressed && key == ESC) {
      key = 0; // ESCキーの処理を無効化
      exit();
    }
    
    // Cキーで設定画面に戻る
    if (keyPressed && (key == 'c' || key == 'C')) {
      exit();
    }
  }
  
  public void movieEvent(Movie m) {
    if (m != null) {
      m.read();
    }
  }
  
  public void exit() {
    if (movie != null) {
      movie.stop();
    }
    super.exit();
  }
}

void updateTimerList() {
  timerListGUI.setItems(new String[0], 0); // クリア
  String[] items = new String[timerList.size()];
  for (int i = 0; i < timerList.size(); i++) {
    TimerData timer = timerList.get(i);
    String status = timer.enabled ? "[ON]" : "[OFF]";
    String playStatus = timer.hasPlayed ? "[PLAYED]" : "[WAITING]";
    String timeStr = nf(timer.hour, 2) + ":" + nf(timer.minute, 2) + ":" + nf(timer.second, 2);
    items[i] = status + playStatus + " " + timer.name + " - " + timeStr + " - " + timer.videoFile;
  }
  timerListGUI.setItems(items, 0);
}

void toggleMultipleTimerUI() {
  useMultipleTimerUI = !useMultipleTimerUI;
  
  for (int i = 0; i < maxTimers; i++) {
    timerHourFields.get(i).setVisible(useMultipleTimerUI);
    timerMinuteFields.get(i).setVisible(useMultipleTimerUI);
    timerSecondFields.get(i).setVisible(useMultipleTimerUI);
    timerNameFields.get(i).setVisible(useMultipleTimerUI);
    timerVideoFields.get(i).setVisible(useMultipleTimerUI);
    timerEnabledBoxes.get(i).setVisible(useMultipleTimerUI);
  }
  
  if (useMultipleTimerUI) {
    btnSettings.setText("Hide Multi UI");
    // ウィンドウサイズを拡張
    surface.setSize(800, 800);
  } else {
    btnSettings.setText("Multi Timer UI");
    surface.setSize(800, 600);
  }
}

void collectMultipleTimerData() {
  // 複数タイマーUIから設定を収集
  timerList.clear();
  
  for (int i = 0; i < maxTimers; i++) {
    if (timerEnabledBoxes.get(i).isSelected()) {
      try {
        int h = Integer.parseInt(timerHourFields.get(i).getText());
        int m = Integer.parseInt(timerMinuteFields.get(i).getText());
        int s = Integer.parseInt(timerSecondFields.get(i).getText());
        String name = timerNameFields.get(i).getText();
        String video = timerVideoFields.get(i).getText();
        
        timerList.add(new TimerData(name, h, m, s, 0, video));
      } catch (NumberFormatException e) {
        lblStatus.setText("Error in Timer " + (i+1) + ": Invalid time format");
        return;
      }
    }
  }
  
  updateTimerList();
  lblStatus.setText("Collected " + timerList.size() + " timers from UI");
}

// G4P イベントハンドラ
void handleButtonEvents(GButton button, GEvent event) {
  if (button == btnAdd && event == GEvent.CLICKED) {
    try {
      String name = tfName.getText();
      int h = Integer.parseInt(tfHour.getText());
      int m = Integer.parseInt(tfMinute.getText());
      int s = Integer.parseInt(tfSecond.getText());
      String videoFile = tfVideoFile.getText();
      
      timerList.add(new TimerData(name, h, m, s, 0, videoFile));
      updateTimerList();
      lblStatus.setText("Timer added: " + name);
    } catch (NumberFormatException e) {
      lblStatus.setText("Error: Invalid time format");
    }
  }
  
  if (button == btnDelete && event == GEvent.CLICKED) {
    int selected = timerListGUI.getSelectedIndex();
    if (selected >= 0 && selected < timerList.size()) {
      TimerData removed = timerList.remove(selected);
      updateTimerList();
      lblStatus.setText("Deleted: " + removed.name);
    }
  }
  
  if (button == btnReset && event == GEvent.CLICKED) {
    // すべてのタイマーのhasPlayedをリセット
    for (TimerData timer : timerList) {
      timer.reset();
    }
    updateTimerList();
    lblStatus.setText("All timers reset - ready for replay");
  }
  
  if (button == btnStart && event == GEvent.CLICKED) {
    if (useMultipleTimerUI) {
      collectMultipleTimerData();
    }
    screenMode = 1;
    lblStatus.setText("Timer monitoring started");
  }
  
  if (button == btnSettings && event == GEvent.CLICKED) {
    toggleMultipleTimerUI();
  }
  
  if (button == btnOpenExecutionWindow && event == GEvent.CLICKED) {
    // テスト用の実行ウィンドウを開く
    if (timerList.size() > 0) {
      TimerData testTimer = timerList.get(0);
      openExecutionWindow(testTimer);
      lblStatus.setText("Test execution window opened");
    } else {
      lblStatus.setText("No timers available for test");
    }
  }
}
