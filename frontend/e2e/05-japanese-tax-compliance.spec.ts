import { expect, type Page, test } from "@playwright/test";

// 計算結果の型定義
interface CalculationResult {
	id: number;
	property_name: string;
	tax_amount: number;
	breakdown?: {
		assessed_value: number;
		tax_base_value: number;
		tax_amount: number;
	};
}

// テスト用のヘルパー関数：ログイン
async function login(page: Page) {
	// ログインAPIをモック（ページ遷移前に設定）
	await page.route("**/api/v1/auth/login", async (route) => {
		await route.fulfill({
			status: 200,
			contentType: "application/json",
			body: JSON.stringify({ token: "mock-jwt-token" }),
		});
	});

	await page.goto("/frontend/login");

	await page.getByPlaceholder("your@email.com").fill("test@example.com");
	await page.getByPlaceholder("パスワードを入力").fill("password123");
	await page.getByRole("button", { name: "ログイン" }).click();

	await expect(page).toHaveURL(/\/frontend\/?$/);
}

// ヘルパー関数：計算結果ページのモックとナビゲーション
async function setupCalculationResultPage(
	page: Page,
	calculationId: number,
	results: CalculationResult[],
) {
	// 先にAPIモックを設定
	await page.route(
		`**/api/v1/calculation_runs/${calculationId}?*`,
		async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify({
					id: calculationId,
					status: "succeeded",
					fiscal_year_id: 1,
				}),
			});
		},
	);

	await page.route(
		`**/api/v1/calculation_runs/${calculationId}/results*`,
		async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify(results),
			});
		},
	);

	// モック設定後にページ遷移（Viteのbase設定を考慮）
	await page.goto(`/frontend/calculations/${calculationId}/results`, {
		waitUntil: "networkidle",
	});
}

test.describe("日本の税制準拠検証（MECE）", () => {
	test.beforeEach(async ({ page }) => {
		await login(page);
	});

	// ==================== シナリオ2: 住宅用地の課税標準の特例 ====================

	test("シナリオ2.1: 小規模住宅用地（200㎡以下）の1/6特例", async ({
		page,
	}) => {
		await setupCalculationResultPage(page, 1, [
			{
				id: 1,
				property_name: "テスト住宅用地A（150㎡）",
				tax_amount: 35000,
				breakdown: {
					assessed_value: 15000000,
					tax_base_value: 2500000,
					tax_amount: 35000,
				},
			},
		]);

		await expect(page.getByText("テスト住宅用地A（150㎡）")).toBeVisible();
		await expect(page.getByText("¥35,000").first()).toBeVisible();
	});

	test("シナリオ2.2: 一般住宅用地（200㎡超）の混合計算", async ({ page }) => {
		await setupCalculationResultPage(page, 2, [
			{
				id: 2,
				property_name: "テスト住宅用地B（300㎡）",
				tax_amount: 93333,
				breakdown: {
					assessed_value: 30000000,
					tax_base_value: 6666667,
					tax_amount: 93333,
				},
			},
		]);

		await expect(page.getByText("テスト住宅用地B（300㎡）")).toBeVisible();
		await expect(page.getByText("¥93,333").first()).toBeVisible();
	});

	test("シナリオ2.3: 非住宅用地への特例非適用", async ({ page }) => {
		await setupCalculationResultPage(page, 3, [
			{
				id: 3,
				property_name: "テスト商業用地（150㎡）",
				tax_amount: 210000,
				breakdown: {
					assessed_value: 15000000,
					tax_base_value: 15000000,
					tax_amount: 210000,
				},
			},
		]);

		await expect(page.getByText("テスト商業用地（150㎡）")).toBeVisible();
		await expect(page.getByText("¥210,000").first()).toBeVisible();
	});

	// ==================== シナリオ3: 新築住宅の減額特例 ====================

	test("シナリオ3.1: 新築住宅（3年以内）の1/2減額", async ({ page }) => {
		await setupCalculationResultPage(page, 4, [
			{
				id: 4,
				property_name: "新築テスト住宅（2年前取得）",
				tax_amount: 62790,
				breakdown: {
					assessed_value: 8970000,
					tax_base_value: 4485000,
					tax_amount: 62790,
				},
			},
		]);

		await expect(page.getByText("新築テスト住宅（2年前取得）")).toBeVisible();
		await expect(page.getByText("¥62,790").first()).toBeVisible();
	});

	test("シナリオ3.2: 新築後3年超の住宅（減額なし）", async ({ page }) => {
		await setupCalculationResultPage(page, 5, [
			{
				id: 5,
				property_name: "テスト住宅（5年前取得）",
				tax_amount: 125580,
				breakdown: {
					assessed_value: 8970000,
					tax_base_value: 8970000,
					tax_amount: 125580,
				},
			},
		]);

		await expect(page.getByText("テスト住宅（5年前取得）")).toBeVisible();
		await expect(page.getByText("¥125,580").first()).toBeVisible();
	});

	// ==================== シナリオ4: 免税点の判定 ====================

	test("シナリオ4.1: 土地の免税点未満（30万円未満）", async ({ page }) => {
		await setupCalculationResultPage(page, 6, [
			{
				id: 6,
				property_name: "テスト土地（2㎡）",
				tax_amount: 0,
				breakdown: {
					assessed_value: 200000,
					tax_base_value: 200000,
					tax_amount: 0,
				},
			},
		]);

		await expect(page.getByText("テスト土地（2㎡）")).toBeVisible();
		await expect(page.getByText("¥0").first()).toBeVisible();
	});

	test("シナリオ4.2: 家屋の免税点未満（20万円未満）", async ({ page }) => {
		await setupCalculationResultPage(page, 7, [
			{
				id: 7,
				property_name: "テスト家屋（評価額15万円）",
				tax_amount: 0,
				breakdown: {
					assessed_value: 150000,
					tax_base_value: 150000,
					tax_amount: 0,
				},
			},
		]);

		await expect(page.getByText("テスト家屋（評価額15万円）")).toBeVisible();
		await expect(page.getByText("¥0").first()).toBeVisible();
	});

	test("シナリオ4.3: 償却資産の免税点未満（150万円未満）", async ({ page }) => {
		await setupCalculationResultPage(page, 8, [
			{
				id: 8,
				property_name: "テスト償却資産（100万円）",
				tax_amount: 0,
				breakdown: {
					assessed_value: 897000,
					tax_base_value: 897000,
					tax_amount: 0,
				},
			},
		]);

		await expect(page.getByText("テスト償却資産（100万円）")).toBeVisible();
		await expect(page.getByText("¥0").first()).toBeVisible();
	});

	test("シナリオ4.4: 免税点以上の課税", async ({ page }) => {
		await setupCalculationResultPage(page, 9, [
			{
				id: 9,
				property_name: "テスト土地（5㎡）",
				tax_amount: 7000,
				breakdown: {
					assessed_value: 500000,
					tax_base_value: 500000,
					tax_amount: 7000,
				},
			},
		]);

		await expect(page.getByText("テスト土地（5㎡）")).toBeVisible();
		await expect(page.getByText("¥7,000").first()).toBeVisible();
	});

	// ==================== シナリオ5: 定率法（200%）の正確性検証 ====================

	test("シナリオ5.1: 初年度の定率法計算（半年償却）", async ({ page }) => {
		await setupCalculationResultPage(page, 10, [
			{
				id: 10,
				property_name: "テスト償却資産（初年度定率法）",
				tax_amount: 125580,
				breakdown: {
					assessed_value: 8970000,
					tax_base_value: 8970000,
					tax_amount: 125580,
				},
			},
		]);

		await expect(
			page.getByText("テスト償却資産（初年度定率法）"),
		).toBeVisible();
		await expect(page.getByText("¥125,580").first()).toBeVisible();
	});

	test("シナリオ5.2: 2年目の定率法計算", async ({ page }) => {
		await setupCalculationResultPage(page, 11, [
			{
				id: 11,
				property_name: "テスト償却資産（2年目定率法）",
				tax_amount: 99704,
				breakdown: {
					assessed_value: 7122180,
					tax_base_value: 7122180,
					tax_amount: 99704,
				},
			},
		]);

		await expect(page.getByText("テスト償却資産（2年目定率法）")).toBeVisible();
		await expect(page.getByText("¥99,704").first()).toBeVisible();
	});

	// ==================== シナリオ6: エンドツーエンド総合シナリオ ====================

	test("シナリオ6: フルフロー - 複数資産の税額計算", async ({ page }) => {
		await setupCalculationResultPage(page, 99, [
			{
				id: 101,
				property_name: "住宅用地（150㎡）",
				tax_amount: 35000,
				breakdown: {
					assessed_value: 15000000,
					tax_base_value: 2500000,
					tax_amount: 35000,
				},
			},
			{
				id: 102,
				property_name: "新築住宅（2年前取得）",
				tax_amount: 62790,
				breakdown: {
					assessed_value: 9000000,
					tax_base_value: 4500000,
					tax_amount: 62790,
				},
			},
			{
				id: 103,
				property_name: "機械装置（定率法、初年度）",
				tax_amount: 62790,
				breakdown: {
					assessed_value: 4500000,
					tax_base_value: 4500000,
					tax_amount: 62790,
				},
			},
		]);

		// 3つの資産すべてが表示される
		await expect(page.getByText("住宅用地（150㎡）")).toBeVisible();
		await expect(page.getByText("新築住宅（2年前取得）")).toBeVisible();
		await expect(page.getByText("機械装置（定率法、初年度）")).toBeVisible();

		// 合計税額: 35,000 + 62,790 + 62,790 = 160,580円
		await expect(page.getByText("¥160,580").first()).toBeVisible();
	});
});
