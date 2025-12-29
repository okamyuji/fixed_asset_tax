# 固定資産税計算システム

## 概要

このシステムは、固定資産税の計算と管理を行うフルスタックWebアプリケーションです。
Rails APIバックエンドとReact/TypeScriptフロントエンドで構成され、
マルチテナント対応、個人/法人の両対応、複数自治体・複数年度の比較機能を備えています。

## 主要機能

- **マルチテナント対応**: 安全なデータ分離と柔軟なスケーラビリティ
- **個人/法人対応**: 統一されたインターフェースで両者を管理
- **複数自治体対応**: 自治体ごとの税率・特例に対応
- **複数年度比較**: 年度別のデータ保存により比較分析が可能
- **減価償却計算**: 定額法・定率法に対応した柔軟な計算エンジン
- **監査証跡**: 計算実行履歴と結果の保存による説明責任の確保
- **モダンUI**: React + Tailwind CSSによる直感的なユーザーインターフェース

## 日本の税制準拠

本システムは日本の固定資産税法および減価償却制度に準拠した正確な計算を実装しています。

### 実装済みの税制対応

#### 1. 200%定率法の正確な計算

- 償却率 = 定額法償却率 × 2.0
- 耐用年数2〜30年の保証率テーブル
- 償却保証額を下回った場合の改定償却率への自動切り替え
- 残存価額（取得価額の1%）の制御

#### 2. 固定資産税評価上の減価計算

- 初年度の半年償却（評価額 = 取得価額 × (1 - 減価率 × 0.5)）
- 2年目以降の計算（評価額 = 前年度評価額 × (1 - 減価率)）
- 最低限度額（取得価額の5%）の適用
- 耐用年数別の減価率テーブル（旧定率法ベース）

#### 3. 課税標準額の特例・減額措置

- **住宅用地の課税標準の特例**
    - 小規模住宅用地（200㎡以下）: 評価額 × 1/6
    - 一般住宅用地（200㎡超）: 評価額 × 1/3
- **新築住宅の減額特例**
    - 新築後3年間: 課税標準額 × 1/2

#### 4. 免税点の判定

- 土地: 30万円未満は非課税
- 家屋: 20万円未満は非課税
- 償却資産: 150万円未満は非課税

#### 5. 標準税率の適用

- 固定資産税: 1.4%（標準税率）

### テストカバレッジ

- バックエンドユニットテスト: 64件（定率法27件、固定資産税評価15件、課税標準額22件）
- フロントエンドE2Eテスト: 全業務フローをカバー
- すべてのテストで正常系・異常系・境界値・エッジケースを検証

## 技術スタック

### バックエンド

- **Ruby 3.4.8**
- **Rails 8.1.1**
- **MySQL 8.0** (Dockerコンテナで実行)
- **JWT認証**
- **Minitest** + **FactoryBot** (テスト)
- **RuboCop** (Linter)

### フロントエンド

- **React 19.2.0**
- **TypeScript 5.9.3**
- **Vite 7.2.4** (ビルドツール)
- **Tailwind CSS 4.1.18** (スタイリング)
- **React Router 7.11.0** (ルーティング)
- **TanStack Query 5.90.14** (サーバー状態管理)
- **Zustand 5.0.9** (グローバル状態管理)
- **React Hook Form 7.69.0** + **Zod 4.2.1** (フォーム管理・バリデーション)
- **Axios 1.13.2** (HTTP通信)
- **Vitest 4.0.16** (ユニットテスト)
- **Playwright 1.57.0** (E2Eテスト)
- **ESLint 9.39.1** (Linter)

### インフラ

- **Docker** + **Docker Compose**
- **マルチステージビルド** (本番環境最適化)

## アーキテクチャ

### データファースト設計

このプロジェクトはデータファースト設計を採用しています。

- 先にDBスキーマ（テーブル構造）を確定
- その後にRailsのモデルや関連コードをDBに合わせて生成・調整
- マイグレーションでDB構造を先に定義
- ドメイン駆動設計（DDD）の原則に従った実装
- テナント分離による安全なマルチテナント運用

### 主要コンポーネント

#### バックエンド - モデル層

- **Tenant**: テナント（契約単位）
- **User**: ユーザー（認証）
- **Party**: 納税義務者（個人/法人の統一表現）
    - Individual: 個人
    - Corporation: 法人
- **Property**: 資産（土地/建物/償却資産グループ）
- **FixedAsset**: 固定資産（償却資産）
- **DepreciationPolicy**: 減価償却ポリシー
- **AssetValuation**: 年度別資産評価
- **CalculationRun**: 税額計算実行
- **CalculationResult**: 計算結果

#### バックエンド - サービス層

- **Tax::DepreciationCalculator**: 減価償却計算
- **Tax::PropertyTaxCalculator**: 固定資産税計算

#### フロントエンド - 画面構成

- **認証画面**: ログイン
- **ダッシュボード**: 概要表示
- **資産管理**: Property（資産）のCRUD
- **固定資産管理**: FixedAsset（固定資産）のCRUD
- **税額計算**: CalculationRun実行と結果表示

## データベース設計

### 主要テーブル

- **tenants**: テナント情報
- **users**: ユーザー情報
- **memberships**: ユーザーとテナントの関連
- **parties**: 納税義務者（STI: Individual/Corporation）
- **municipalities**: 自治体マスタ
- **fiscal_years**: 年度マスタ
- **properties**: 資産
- **land_parcels**: 土地の筆
- **fixed_assets**: 固定資産（償却資産）
- **depreciation_policies**: 減価償却ポリシー
- **asset_valuations**: 年度別資産評価
- **depreciation_years**: 年度別減価償却結果
- **calculation_runs**: 計算実行履歴
- **calculation_results**: 計算結果

### マルチテナント設計

全ての業務テーブルに`tenant_id`を持たせ、行レベルでデータを分離しています。
`TenantScoped` concernにより、自動的にテナントスコープが適用されます。

## セットアップ

### 前提条件

- Docker Desktop がインストールされていること
- Node.js 18以上（フロントエンド開発時）
- Ruby 3.4.8（バックエンド開発時）

### Docker Composeで起動（推奨）

```bash
# アプリケーション全体をビルド・起動
docker compose up --build

# バックグラウンドで起動
docker compose up -d --build

# データベースのマイグレーション（初回のみ）
docker compose exec web bin/rails db:create db:migrate

# ログ確認
docker compose logs -f web

# 停止
docker compose down
```

アプリケーションは `http://localhost:3000` でアクセス可能です。

### ローカル開発環境

#### ローカルでのバックエンド起動

```bash
# 依存関係インストール
bundle install

# Dockerでデータベース起動
docker compose up -d db

# データベース作成とマイグレーション
DB_PASSWORD=password bin/rails db:create db:migrate

# サーバー起動
DB_PASSWORD=password bin/rails server
```

#### ローカルでのフロントエンド起動

```bash
# フロントエンドディレクトリに移動
cd frontend

# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev
```

フロントエンド開発サーバーは `http://localhost:5173` で起動します。

## テスト

### ローカルでのバックエンドテスト

```bash
# ユニットテスト実行
DB_PASSWORD=password bin/rails test

# Linter実行
bundle exec rubocop
```

**テスト結果**: 31 runs, 87 assertions, 0 failures, 0 errors, 0 skips

### ローカルでのフロントエンドテスト

```bash
cd frontend

# ユニットテスト実行
npm run test -- --run

# テストカバレッジ
npm run test:coverage

# E2Eテスト実行（要：バックエンド起動）
npm run test:e2e

# E2EテストUI表示
npm run test:e2e:ui

# Linter実行
npm run lint

# ビルド確認
npm run build
```

**E2Eテスト**: 全業務フローをカバー（認証、資産管理、固定資産管理、税額計算）

## API エンドポイント

### 認証

#### ログイン

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

レスポンス:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### 資産管理

#### 資産一覧取得

```http
GET /api/v1/properties
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

#### 資産作成

```http
POST /api/v1/properties
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
Content-Type: application/json

{
  "property": {
    "party_id": 1,
    "municipality_id": 1,
    "category": "land",
    "name": "東京都千代田区の土地"
  }
}
```

#### 資産更新

```http
PUT /api/v1/properties/{id}
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
Content-Type: application/json

{
  "property": {
    "name": "更新後の資産名"
  }
}
```

#### 資産削除

```http
DELETE /api/v1/properties/{id}
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

### 固定資産（償却資産）

#### 固定資産一覧取得

```http
GET /api/v1/properties/{property_id}/fixed_assets
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

#### 固定資産作成

```http
POST /api/v1/properties/{property_id}/fixed_assets
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
Content-Type: application/json

{
  "fixed_asset": {
    "name": "製造機械A",
    "acquired_on": "2020-01-01",
    "acquisition_cost": 10000000,
    "asset_type": "machinery"
  },
  "depreciation_policy": {
    "method": "straight_line",
    "useful_life_years": 10,
    "residual_rate": 0.1
  }
}
```

#### 固定資産更新

```http
PUT /api/v1/fixed_assets/{id}
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
Content-Type: application/json

{
  "fixed_asset": {
    "name": "更新後の固定資産名"
  }
}
```

#### 固定資産削除

```http
DELETE /api/v1/fixed_assets/{id}
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

### 税額計算

#### 計算実行一覧取得

```http
GET /api/v1/calculation_runs
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

#### 固定資産税計算実行

```http
POST /api/v1/calculation_runs
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
Content-Type: application/json

{
  "municipality_id": 1,
  "fiscal_year_id": 1
}
```

レスポンス:

```json
{
  "id": 1,
  "municipality_id": 1,
  "municipality_name": "東京都千代田区",
  "fiscal_year_id": 1,
  "fiscal_year": 2025,
  "status": "succeeded",
  "results": [
    {
      "id": 1,
      "property_id": 1,
      "property_name": "東京都千代田区の土地",
      "tax_amount": 210000.0,
      "breakdown": {
        "assessed_value": 15000000,
        "tax_base_value": 15000000,
        "tax_rate": 0.014,
        "tax_amount": 210000.0
      }
    }
  ]
}
```

#### 計算結果詳細取得

```http
GET /api/v1/calculation_runs/{id}
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}
```

## セキュリティ

- **JWT認証**: 安全なAPI認証
- **テナントスコープ**: データ漏洩防止の強制
- **CORS設定**: 適切なオリジン制限
- **パスワードハッシュ化**: bcryptによる安全な保存
- **コード品質**: RuboCop（違反0件）、ESLint（違反0件）

## プロジェクト構成

```text
.
├── app/                    # Railsアプリケーション
│   ├── controllers/        # APIコントローラー
│   ├── models/             # データモデル
│   └── services/           # ビジネスロジック
├── config/                 # Rails設定
├── db/                     # データベース
│   ├── migrate/            # マイグレーション
│   └── schema.rb           # スキーマ定義
├── frontend/               # Reactフロントエンド
│   ├── src/
│   │   ├── api/            # API通信
│   │   ├── components/     # 共通コンポーネント
│   │   ├── hooks/          # カスタムフック
│   │   ├── pages/          # 画面コンポーネント
│   │   ├── stores/         # 状態管理
│   │   └── types/          # TypeScript型定義
│   ├── e2e/                # E2Eテスト
│   └── dist/               # ビルド成果物
├── test/                   # バックエンドテスト
│   ├── factories/          # テストデータ
│   ├── models/             # モデルテスト
│   ├── services/           # サービステスト
│   └── integration/        # 統合テスト
├── compose.yml             # Docker Compose設定
├── Dockerfile.multistage   # マルチステージビルド
└── README.md               # このファイル
```

## 今後の拡張

- 税率・特例のマスタ化
- 自治体ごとの税率設定
- 負担調整措置の実装
- 土地の評価額自動計算
- レポート機能（PDF出力）
- CSV/Excel入出力
- 通知機能（メール・Slack）
- ダッシュボードグラフ表示
- 多言語対応（i18n）
- 監査ログ機能

## トラブルシューティング

### データベース接続エラー

```bash
# MySQLコンテナの状態確認
docker compose ps

# MySQLコンテナの再起動
docker compose restart db

# ログ確認
docker compose logs db
```

### フロントエンドビルドエラー

```bash
# node_modulesを削除して再インストール
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### ポート競合

デフォルトポート（3000, 3306, 5173）が使用中の場合は、`compose.yml`や`vite.config.ts`で変更してください。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
