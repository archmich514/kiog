# KIOG アプリ開発依頼書

## 1. プロジェクト概要

### アプリ名
KIOG（キオグ）

### コンセプト
同棲カップル・家族向けの会話記録アプリ。日常の会話を録音し、AIで要約・レポート化することで、二人の思い出を残す。

### バンドルID
`com.archmich.kiog`

---

## 2. 技術構成

```
【フロントエンド】
iOS（Swift/SwiftUI）+ AVAudioRecorder（バックグラウンド録音対応）

【バックエンド】
Firebase
├── Authentication（ユーザー認証）
├── Firestore（データベース）
├── Storage（音声ファイル一時保存）
├── Cloud Functions（定期実行・API呼び出し）
└── Cloud Messaging（プッシュ通知）

【外部API】
├── Gemini 2.5 Flash API（文字起こし＋話者分離）
└── Claude API（要約・レポート生成）
```

---

## 3. 開発フェーズ

### Phase 1: 静的UI（今回の依頼範囲）
- 全画面のUI実装
- 画面遷移の実装
- Figma MCPを使用してデザインからSwiftUIコード生成

### Phase 2: 認証・ユーザー登録（後日）
- Firebase Authentication
- 名前・性別登録
- UNIT作成・参加

### Phase 3: 録音機能（後日）
- AVAudioRecorder実装
- バックグラウンド録音
- Firebase Storageアップロード

### Phase 4: 文字起こし・レポート生成（後日）
- Cloud Functions
- Gemini API連携
- Claude API連携

### Phase 5: 質問・回答機能（後日）
- 定期通知
- 質問回答フロー

---

## 4. 画面一覧と遷移フロー

```
SplashScreen（スプラッシュ画面）
    ↓ STARTボタン
RegistrationScreen（名前・性別登録画面）
    ↓ NextButton
UnitSelectScreen（UNIT選択画面）
    ├─ 「UNITを作成」→ LivingScreen
    └─ 「UNITに入室」→ LivingScreen
LivingScreen（トップ画面）
    ├─ ReportCard → ReportDetailScreen
    ├─ 「ALL →」→ KiogListScreen
    ├─ QuestionCard → iOS標準入力ポップアップ
    └─ 「RECをはじめる」→ RecordingScreen
KiogListScreen（KIOG一覧画面）
    ├─ ReportCard → ReportDetailScreen
    └─ BackButton → LivingScreen
ReportDetailScreen（レポート詳細画面）
    └─ BackButton → 前の画面
RecordingScreen（録音画面）
    ├─ 「KIOGを生成」→ LivingScreen（モーダル表示後）
    └─ BackButton → 確認モーダル → LivingScreen
```

---

## 5. 画面別レイヤー構造・命名規則

### 5.1 SplashScreen（スプラッシュ画面）

```
SplashScreen（フレーム）
├── LogoImage（画像）※KIOGロゴ、テキスト含む
└── StartButton（フレーム）
    └── StartButtonLabel（テキスト "START"）
```

**StartButton設定：**
- 背景色：`#000000`
- テキスト色：`#FFFFFF`
- 角丸：8px
- 左右マージン：16px

---

### 5.2 RegistrationScreen（名前・性別登録画面）

```
RegistrationScreen（フレーム）
├── ScreenTitle（テキスト "START"）
├── IllustrationImage（画像）
├── InputStack（フレーム）
│   ├── NameTextField（フレーム）
│   │   └── NamePlaceholder / NameValue（テキスト）
│   └── GenderSelectField（フレーム）
│       └── GenderPlaceholder / GenderValue（テキスト）
└── NextButtonContainer（フレーム）
    └── NextButton（フレーム）
        └── NextButtonIcon（Vector ">"）
```

**NameTextField / GenderSelectField：**
- 背景色：`#FFFFFF`
- 角丸：8px
- プレースホルダー色：`#999999`
- 入力済みテキスト色：`#000000`

**NextButton（円形）：**
- サイズ：64×64px
- 角丸：32px（正円）
- 非活性時：背景 `#CCCCCC`、アイコン `#999999`
- 活性時：背景 `#000000`、アイコン `#FFFFFF`

**入力動作：**
- NameTextField：タップでキーボード表示、テキスト入力
- GenderSelectField：タップでiOS標準Picker表示（男性/女性）
- 両方入力完了でNextButtonが活性化

---

### 5.3 UnitSelectScreen（UNIT選択画面）

```
UnitSelectScreen（フレーム）
├── ScreenTitle（テキスト "UNIT"）
├── IllustrationImage（画像）※性別で切り替え
├── UnitIdTextField（フレーム）
│   └── UnitIdPlaceholder / UnitIdValue（テキスト）
└── ButtonStack（フレーム）
    ├── JoinUnitButton（フレーム）
    │   └── JoinUnitButtonLabel（テキスト "UNITに入室"）
    └── CreateUnitButton（フレーム）
        └── CreateUnitButtonLabel（テキスト "UNITを作成"）
```

**イラスト切り替え：**
- 前画面で「男性」選択 → 男性イラスト表示
- 前画面で「女性」選択 → 女性イラスト表示

**JoinUnitButton：**
- 非活性時：背景 `#CCCCCC`、テキスト色 `#999999`
- 活性時：背景 `#000000`、テキスト色 `#FFFFFF`
- UnitIdTextField入力で活性化

**CreateUnitButton：**
- 常に活性：背景 `#000000`、テキスト色 `#FFFFFF`

---

### 5.4 LivingScreen（トップ画面）

```
LivingScreen（フレーム）
├── ScrollContent（フレーム）※スクロール領域
│   ├── HeaderStack（フレーム）
│   │   ├── ScreenTitle（テキスト "LIVING"）
│   │   └── UnitIdLabel（テキスト "#{Unit ID}"）
│   ├── KiogSection（フレーム）
│   │   ├── KiogHeader（フレーム）
│   │   │   ├── SectionTitle（テキスト "KIOG"）
│   │   │   └── AllLink（テキスト "ALL →"）
│   │   └── KiogList（フレーム）
│   │       ├── ReportCard
│   │       ├── ReportCard
│   │       └── ReportCard（最大3件）
│   ├── QueSection（フレーム）
│   │   ├── SectionTitle（テキスト "Que"）
│   │   └── QueList（フレーム）
│   │       ├── QuestionCard
│   │       ├── QuestionCard
│   │       └── QuestionCard
│   └── AnswerSection（フレーム）
│       ├── SectionTitle（テキスト "Answer"）
│       └── AnswerCard（フレーム）
│           ├── AnswerName（テキスト "{Name}"）
│           ├── AnswerQuestion（テキスト "{Question}"）
│           └── AnswerText（テキスト "{Another User Answer}"）
└── Footer（フレーム）※画面下部に固定
    └── StartRecordingButton（フレーム）
        └── StartRecordingButtonLabel（テキスト "RECをはじめる"）
```

**【重要】Footer固定について：**
- Footerは画面下部に常に固定（スクロールしても位置が変わらない）
- 縦パディング：32px
- Figma上では固定設定ができていないが、SwiftUI実装時に固定フッターとして実装すること

**ReportCard（オレンジ）：**
- 背景色：`#F5A623`
- 角丸：8px
- テキスト色：`#FFFFFF`
- 表示内容：`{month}/{day}`

**QuestionCard（緑）：**
- 背景色：`#4CAF50`
- 角丸：8px
- テキスト色：`#FFFFFF`
- タップ → iOS標準アラートで入力、送信

**AnswerCard（サーモンピンク）：**
- 背景色：`#E07A5F`
- 角丸：8px
- テキスト色：`#FFFFFF`
- 高さ：Hug contents（内容に応じて可変）

**空状態（KIOGがない場合）：**
- KiogListの代わりに「KIOGはありません」テキスト表示
- QueSection、AnswerSectionは非表示

---

### 5.5 KiogListScreen（KIOG一覧画面）

```
KiogListScreen（フレーム）
├── Header（フレーム）
│   ├── BackButton（フレーム）
│   │   └── BackIcon（Vector "<"）
│   └── ScreenTitle（テキスト "KIOG"）
└── ReportList（フレーム）
    ├── ReportCard
    ├── ReportCard
    └── ReportCard
    ...（スクロール可能、全件表示）
```

**BackButton：**
- タップ領域：44×44px確保
- LivingScreenに戻る

---

### 5.6 ReportDetailScreen（レポート詳細画面）

```
ReportDetailScreen（フレーム）
├── Header（フレーム）
│   ├── BackButton（フレーム）
│   │   └── BackIcon（Vector "<"）
│   └── ScreenTitle（テキスト "{Day/Month}"）
└── ReportContent（フレーム）
    ├── ReportDate（テキスト "{Day/Month}"）
    └── ReportText（テキスト "{Report}"）
```

**ReportContent：**
- 背景色：`#FFFFFF`
- 角丸：12px
- パディング：16px
- 高さ：Hug contents

---

### 5.7 RecordingScreen（録音画面）

```
RecordingScreen（フレーム）
├── Header（フレーム）
│   ├── BackButton（フレーム）
│   │   └── BackIcon（Vector "<"）
│   └── ScreenTitle（テキスト "REC"）
├── TimerDisplay（フレーム）
│   └── TimerText（テキスト "{RecordingTime} / 90:00"）
└── GenerateButton（フレーム）
    └── GenerateButtonLabel（テキスト "KIOGを生成"）
```

**TimerText：**
- フォントサイズ：大きめ（32〜40pt）
- フォントウェイト：Bold

**GenerateButton：**
- 背景色：`#000000`
- テキスト色：`#FFFFFF`

**モーダル処理（iOS標準UIAlertController使用）：**

1. 「KIOGを生成」ボタン押下時：
   - モーダル表示：「生成までに時間がかかります。生成が完了したら通知を送ります」
   - ボタン：「完了」のみ
   - 完了押下 → LivingScreenに遷移

2. BackButton押下時：
   - モーダル表示：「レコーディングを終了してKIOGを生成しますか？」
   - ボタン3つ：
     - 「終了しKIOGを生成」→ 上記1と同じ処理
     - 「KIOGを生成せずに終了」→ 録音データ削除、LivingScreenに遷移
     - 「キャンセル」→ モーダルを閉じる

---

## 6. 共通コンポーネント

### 6.1 PrimaryButton（メインボタン）

```swift
// 使用箇所：StartButton, CreateUnitButton, GenerateButton, StartRecordingButton
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    // 背景色：#000000
    // テキスト色：#FFFFFF
    // 角丸：8px
    // 左右マージン：16px
}
```

### 6.2 SecondaryButton（サブボタン）

```swift
// 使用箇所：JoinUnitButton
struct SecondaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    // 非活性：背景 #CCCCCC、テキスト #999999
    // 活性：背景 #000000、テキスト #FFFFFF
}
```

### 6.3 NextButton（円形ボタン）

```swift
// 使用箇所：RegistrationScreen
struct NextButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    // サイズ：64×64px
    // 角丸：32px（正円）
    // 非活性：背景 #CCCCCC、アイコン #999999
    // 活性：背景 #000000、アイコン #FFFFFF
}
```

### 6.4 BackButton（戻るボタン）

```swift
// 使用箇所：KiogListScreen, ReportDetailScreen, RecordingScreen
struct BackButton: View {
    let action: () -> Void
    
    // タップ領域：44×44px
    // アイコン：< (Vector)
}
```

### 6.5 TextField（入力フィールド）

```swift
// 使用箇所：NameTextField, UnitIdTextField
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    // 背景色：#FFFFFF
    // 角丸：8px
    // プレースホルダー色：#999999
    // 入力テキスト色：#000000
}
```

### 6.6 SelectField（選択フィールド）

```swift
// 使用箇所：GenderSelectField
struct SelectField: View {
    let placeholder: String
    let selectedValue: String?
    let action: () -> Void
    
    // iOS標準Pickerを下からモーダル表示
}
```

### 6.7 ReportCard（レポートカード）

```swift
struct ReportCard: View {
    let dateText: String  // "{month}/{day}"
    let action: () -> Void
    
    // 背景色：#F5A623
    // 角丸：8px
    // テキスト色：#FFFFFF
}
```

### 6.8 QuestionCard（質問カード）

```swift
struct QuestionCard: View {
    let questionText: String
    let action: () -> Void
    
    // 背景色：#4CAF50
    // 角丸：8px
    // テキスト色：#FFFFFF
}
```

### 6.9 AnswerCard（回答カード）

```swift
struct AnswerCard: View {
    let name: String
    let question: String
    let answer: String
    
    // 背景色：#E07A5F
    // 角丸：8px
    // テキスト色：#FFFFFF
    // 高さ：Hug contents
}
```

---

## 7. カラーパレット

| 名前 | HEX | 用途 |
|------|-----|------|
| Primary | `#000000` | メインボタン背景、活性アイコン |
| Background | `#FDF6EC` | 画面背景（クリーム色） |
| White | `#FFFFFF` | カード背景、ボタンテキスト |
| Gray | `#CCCCCC` | 非活性ボタン背景 |
| GrayText | `#999999` | プレースホルダー、非活性テキスト |
| Orange | `#F5A623` | ReportCard背景 |
| Green | `#4CAF50` | QuestionCard背景 |
| Salmon | `#E07A5F` | AnswerCard背景 |

---

## 8. Figma MCP連携

### セットアップ

Claude CodeにFigma MCPを設定する。

**必要な情報：**
- https://www.figma.com/design/42Rolq6LrQJgP5FOEfN4WH/Kiog?node-id=1-28&t=xTpCb6Q98tK2HUr4-0
上記のデザインファイルにFigma MCPでアクセスする

---

## 9. プロジェクト構成（推奨）

```
KIOG/
├── KIOG.xcodeproj
├── KIOG/
│   ├── KIOGApp.swift
│   ├── ContentView.swift
│   ├── Views/
│   │   ├── SplashScreen.swift
│   │   ├── RegistrationScreen.swift
│   │   ├── UnitSelectScreen.swift
│   │   ├── LivingScreen.swift
│   │   ├── KiogListScreen.swift
│   │   ├── ReportDetailScreen.swift
│   │   └── RecordingScreen.swift
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── NextButton.swift
│   │   ├── BackButton.swift
│   │   ├── CustomTextField.swift
│   │   ├── SelectField.swift
│   │   ├── ReportCard.swift
│   │   ├── QuestionCard.swift
│   │   └── AnswerCard.swift
│   ├── Models/
│   │   └── （後日追加）
│   ├── Services/
│   │   └── （後日追加）
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── GoogleService-Info.plist
│   └── Info.plist
└── README.md
```

---

## 10. 実装時の重要な注意点

### 10.1 フッター固定
LivingScreenのFooter（RECをはじめるボタン）は、画面下部に固定。ScrollViewの外に配置し、safeAreaを考慮すること。

```swift
// 例
VStack {
    ScrollView {
        // ScrollContent
    }
    
    // Footer - 固定
    Footer()
        .padding(.vertical, 32)
}
```

### 10.2 iOS標準UIの使用
- 性別選択：iOS標準Picker（.pickerStyle(.wheel)）
- 質問回答入力：UIAlertController with TextField
- 確認モーダル：UIAlertController with multiple actions

### 10.3 画像アセット
以下の画像はAssets.xcassetsに追加が必要：
- KIOGロゴ（SplashScreen用）
- 男女イラスト（RegistrationScreen用）
- 男性イラスト（UnitSelectScreen用）
- 女性イラスト（UnitSelectScreen用）

### 10.4 Variantsについて（Figma）
FigmaでのVariants設定方法が不明とのこと。SwiftUI側で状態管理を実装すればOK。
- ボタンの活性/非活性は`isEnabled`プロパティで制御
- テキストフィールドの状態は`@State`で管理

---

## 11. 今回の依頼内容（Phase 1）

### 依頼範囲
1. Xcodeプロジェクトの作成（バンドルID: com.archmich.kiog）
2. 全画面のSwiftUI実装
3. 画面遷移の実装（NavigationStack使用）
4. 共通コンポーネントの実装
5. ダミーデータでの表示確認

### 依頼範囲外（Phase 2以降）
- Firebase連携
- 実際の録音機能
- API連携
- プッシュ通知

### 成果物
- 動作するXcodeプロジェクト
- シミュレータで全画面遷移が確認できる状態

---

## 12. 提供ファイル

以下のファイルを別途提供：
1. GoogleService-Info.plist（Firebase設定、Phase 2で使用）
2. 画像アセット（ロゴ、イラスト）
3. Figmaデザインファイルへのリンク

---

## 13. 質問がある場合

実装中に不明点があれば、以下を確認：
1. この依頼書の該当セクション
2. Figmaデザイン
3. それでも不明な場合は質問してください
