import { expect, type Page, type Route, test } from "@playwright/test";

// テスト用のヘルパー関数：ログイン
async function login(page: Page) {
	// ログインAPIをモック（page.gotoの前に設定）
	await page.route("**/api/v1/auth/login", async (route: Route) => {
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

	await expect(page).toHaveURL("/frontend");
}

test.describe("固定資産CRUD", () => {
	test.beforeEach(async ({ page }) => {
		await login(page);
	});

	test("固定資産一覧ページに遷移できる", async ({ page }) => {
		// 固定資産一覧APIをモック
		await page.route("**/api/v1/fixed_assets*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([]),
			});
		});

		// 直接固定資産一覧ページに遷移
		await page.goto("/frontend/fixed-assets");

		// 固定資産一覧ページが表示される
		await expect(page).toHaveURL("/frontend/fixed-assets");
		await expect(
			page.getByRole("heading", { name: "固定資産管理" }),
		).toBeVisible();
		await expect(page.getByRole("link", { name: "新規登録" })).toBeVisible();
	});

	test("空の固定資産一覧が表示される", async ({ page }) => {
		// 固定資産一覧APIをモック（空配列）
		await page.route("**/api/v1/fixed_assets*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([]),
			});
		});

		await page.goto("/frontend/fixed-assets");

		// 空メッセージを確認
		await expect(
			page.getByText("登録されている固定資産がありません"),
		).toBeVisible();
	});

	test("固定資産一覧が表示される", async ({ page }) => {
		// 固定資産一覧APIをモック
		await page.route("**/api/v1/fixed_assets*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([
					{
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産1",
						asset_type: "機械装置",
						acquired_on: "2024-01-01",
						acquisition_cost: 1000000,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					},
					{
						id: 2,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産2",
						asset_type: "工具器具備品",
						acquired_on: "2024-06-01",
						acquisition_cost: 500000,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					},
				]),
			});
		});

		await page.goto("/frontend/fixed-assets");

		// 固定資産が表示されることを確認
		await expect(page.getByText("テスト固定資産1")).toBeVisible();
		await expect(page.getByText("テスト固定資産2")).toBeVisible();
		await expect(page.getByText("機械装置")).toBeVisible();
		await expect(page.getByText("工具器具備品")).toBeVisible();
		await expect(page.getByText("¥1,000,000")).toBeVisible();
		await expect(page.getByText("¥500,000")).toBeVisible();
	});

	test("新規固定資産作成ページに遷移できる", async ({ page }) => {
		await page.route("**/api/v1/fixed_assets*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([]),
			});
		});

		await page.goto("/frontend/fixed-assets");

		// 新規登録ボタンをクリック
		await page.getByRole("link", { name: "新規登録" }).click();

		// 新規作成ページに遷移
		await expect(page).toHaveURL("/frontend/fixed-assets/new");
		await expect(
			page.getByRole("heading", { name: "固定資産の新規登録" }),
		).toBeVisible();
	});

	test("新規固定資産を作成できる（モック）", async ({ page }) => {
		// 資産分類APIをモック
		await page.route("**/api/v1/asset_classifications", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify({
					asset_classifications: [
						{ key: "tangible", name: "有形固定資産", code: "1" },
						{ key: "intangible", name: "無形固定資産", code: "2" },
						{ key: "deferred", name: "繰延資産", code: "3" },
					],
					account_items: {
						tangible: [
							{
								key: "machinery",
								name: "機械装置",
								code: "104",
								useful_life_range: { min: 2, max: 22 },
								description: "製造設備等",
							},
							{
								key: "tools_furniture_fixtures",
								name: "工具器具備品",
								code: "106",
								useful_life_range: { min: 2, max: 20 },
								description: "パソコン等",
							},
						],
						intangible: [],
						deferred: [],
					},
					depreciation_methods: [],
					depreciation_types: [],
					acquisition_types: [{ key: "new", name: "新品", code: "1" }],
				}),
			});
		});

		await page.route("**/api/v1/fixed_assets*", async (route) => {
			if (route.request().method() === "GET") {
				await route.fulfill({
					status: 200,
					contentType: "application/json",
					body: JSON.stringify([]),
				});
			} else if (route.request().method() === "POST") {
				await route.fulfill({
					status: 201,
					contentType: "application/json",
					body: JSON.stringify({
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "新規テスト固定資産",
						asset_type: "機械装置",
						acquired_on: "2025-01-01",
						acquisition_cost: 2000000,
						asset_category: "カテゴリA",
						notes: "テスト備考",
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					}),
				});
			}
		});

		await page.goto("/frontend/fixed-assets/new");

		// フォームに入力
		await page.getByLabel("資産ID").fill("1");
		await page.getByLabel("資産名").fill("新規テスト固定資産");
		await page.getByLabel("資産分類").selectOption("tangible");
		await page.getByLabel("勘定科目").selectOption("machinery");
		await page.getByLabel("資産種別").fill("機械装置");
		await page.getByLabel("取得日").fill("2025-01-01");
		await page.getByLabel("取得価額").fill("2000000");
		await page.getByLabel("説明").fill("テスト説明");

		// 保存ボタンをクリック
		await page.getByRole("button", { name: "保存" }).click();

		// 一覧ページにリダイレクト
		await expect(page).toHaveURL("/frontend/fixed-assets");
	});

	test("固定資産編集ページに遷移できる", async ({ page }) => {
		// 一覧APIをモック
		await page.route("**/api/v1/fixed_assets?*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([
					{
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産1",
						asset_type: "機械装置",
						acquired_on: "2024-01-01",
						acquisition_cost: 1000000,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					},
				]),
			});
		});

		// 詳細APIをモック
		await page.route("**/api/v1/fixed_assets/1*", async (route) => {
			if (route.request().method() === "GET") {
				await route.fulfill({
					status: 200,
					contentType: "application/json",
					body: JSON.stringify({
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産1",
						asset_type: "機械装置",
						acquired_on: "2024-01-01",
						acquisition_cost: 1000000,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					}),
				});
			}
		});

		await page.goto("/frontend/fixed-assets");

		// 編集ボタンをクリック
		await page.getByRole("link", { name: "編集" }).first().click();

		// 編集ページに遷移
		await expect(page).toHaveURL("/frontend/fixed-assets/1/edit");
		await expect(
			page.getByRole("heading", { name: "固定資産の編集" }),
		).toBeVisible();
	});

	test("固定資産を編集できる（モック）", async ({ page }) => {
		// 資産分類APIをモック
		await page.route("**/api/v1/asset_classifications", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify({
					asset_classifications: [
						{ key: "tangible", name: "有形固定資産", code: "1" },
						{ key: "intangible", name: "無形固定資産", code: "2" },
						{ key: "deferred", name: "繰延資産", code: "3" },
					],
					account_items: {
						tangible: [
							{
								key: "machinery",
								name: "機械装置",
								code: "104",
								useful_life_range: { min: 2, max: 22 },
								description: "製造設備等",
							},
							{
								key: "tools_furniture_fixtures",
								name: "工具器具備品",
								code: "106",
								useful_life_range: { min: 2, max: 20 },
								description: "パソコン等",
							},
						],
						intangible: [],
						deferred: [],
					},
					depreciation_methods: [],
					depreciation_types: [],
					acquisition_types: [{ key: "new", name: "新品", code: "1" }],
				}),
			});
		});

		// 詳細APIをモック
		await page.route("**/api/v1/fixed_assets/1*", async (route) => {
			if (route.request().method() === "GET") {
				await route.fulfill({
					status: 200,
					contentType: "application/json",
					body: JSON.stringify({
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産1",
						asset_type: "機械装置",
						asset_classification: "tangible",
						account_item: "machinery",
						acquired_on: "2024-01-01",
						acquisition_cost: 1000000,
						acquisition_type: "new",
						business_use_ratio: 1.0,
						quantity: 1,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					}),
				});
			} else if (
				route.request().method() === "PATCH" ||
				route.request().method() === "PUT"
			) {
				await route.fulfill({
					status: 200,
					contentType: "application/json",
					body: JSON.stringify({
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "更新されたテスト固定資産",
						asset_type: "機械装置",
						asset_classification: "tangible",
						account_item: "machinery",
						acquired_on: "2024-01-01",
						acquisition_cost: 1500000,
						acquisition_type: "new",
						business_use_ratio: 1.0,
						quantity: 1,
						description: "更新されました",
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					}),
				});
			}
		});

		await page.route("**/api/v1/fixed_assets?*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([]),
			});
		});

		await page.goto("/frontend/fixed-assets/1/edit");

		// フォームを編集
		await page.getByLabel("資産名").fill("更新されたテスト固定資産");
		await page.getByLabel("取得価額").fill("1500000");
		await page.getByLabel("説明").fill("更新されました");

		// 保存ボタンをクリック
		await page.getByRole("button", { name: "保存" }).click();

		// 一覧ページにリダイレクト
		await expect(page).toHaveURL("/frontend/fixed-assets");
	});

	test("固定資産を削除できる（モック）", async ({ page }) => {
		// 一覧APIをモック
		await page.route("**/api/v1/fixed_assets?*", async (route) => {
			await route.fulfill({
				status: 200,
				contentType: "application/json",
				body: JSON.stringify([
					{
						id: 1,
						tenant_id: 1,
						property_id: 1,
						name: "テスト固定資産1",
						asset_type: "機械装置",
						acquired_on: "2024-01-01",
						acquisition_cost: 1000000,
						asset_category: null,
						notes: null,
						created_at: "2025-01-01T00:00:00Z",
						updated_at: "2025-01-01T00:00:00Z",
					},
				]),
			});
		});

		// 削除APIをモック
		await page.route("**/api/v1/fixed_assets/1*", async (route) => {
			if (route.request().method() === "DELETE") {
				await route.fulfill({
					status: 204,
				});
			}
		});

		await page.goto("/frontend/fixed-assets");

		// 削除ボタンをクリック（確認ダイアログを自動承認）
		page.on("dialog", (dialog) => dialog.accept());
		await page.getByRole("button", { name: "削除" }).first().click();

		// 削除が完了するまで待つ
		await page.waitForTimeout(500);
	});
});
