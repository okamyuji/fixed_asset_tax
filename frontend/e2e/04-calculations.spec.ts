import { expect, Page, Route, test } from '@playwright/test';

// テスト用のヘルパー関数：ログイン
async function login(page: Page) {
    // ログインAPIをモック（page.gotoの前に設定）
    await page.route('**/api/v1/auth/login', async (route: Route) => {
        await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({ token: 'mock-jwt-token' }),
        });
    });
    
    await page.goto('/frontend/login');
    
    await page.getByPlaceholder('your@email.com').fill('test@example.com');
    await page.getByPlaceholder('パスワードを入力').fill('password123');
    await page.getByRole('button', { name: 'ログイン' }).click();
    
    await expect(page).toHaveURL('/frontend');
}

test.describe('税額計算フロー', () => {
    test.beforeEach(async ({ page }) => {
        await login(page);
    });

    test('税額計算一覧ページに遷移できる', async ({ page }) => {
        // 計算一覧APIをモック
        await page.route('**/api/v1/calculation_runs*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        // 直接税額計算一覧ページに遷移
        await page.goto('/frontend/calculations');
        
        // 税額計算一覧ページが表示される
        await expect(page).toHaveURL('/frontend/calculations');
        await expect(page.getByRole('heading', { name: '税額計算', level: 1 })).toBeVisible();
        await expect(page.getByRole('link', { name: '新規計算' })).toBeVisible();
    });

    test('空の計算履歴が表示される', async ({ page }) => {
        // 計算一覧APIをモック（空配列）
        await page.route('**/api/v1/calculation_runs*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/calculations');
        
        // 空メッセージを確認
        await expect(page.getByText('計算履歴がありません')).toBeVisible();
    });

    test('計算履歴一覧が表示される', async ({ page }) => {
        // 計算一覧APIをモック
        await page.route('**/api/v1/calculation_runs*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        municipality_id: 1,
                        fiscal_year_id: 1,
                        status: 'queued',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                    {
                        id: 2,
                        tenant_id: 1,
                        municipality_id: 1,
                        fiscal_year_id: 1,
                        status: 'succeeded',
                        created_at: '2025-01-02T00:00:00Z',
                        updated_at: '2025-01-02T00:00:00Z',
                    },
                ]),
            });
        });
        
        await page.goto('/frontend/calculations');
        
        // 計算履歴が表示されることを確認
        await expect(page.getByText('待機中')).toBeVisible();
        await expect(page.getByText('成功')).toBeVisible();
    });

    test('新規計算作成ページに遷移できる', async ({ page }) => {
        await page.route('**/api/v1/calculation_runs*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/calculations');
        
        // 新規計算ボタンをクリック
        await page.getByRole('link', { name: '新規計算' }).click();
        
        // 新規作成ページに遷移
        await expect(page).toHaveURL('/frontend/calculations/new');
        await expect(page.getByRole('heading', { name: '新規税額計算' })).toBeVisible();
    });

    test('新規計算を作成できる（モック）', async ({ page }) => {
        await page.route('**/api/v1/calculation_runs*', async (route) => {
            if (route.request().method() === 'GET') {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify([]),
                });
            } else if (route.request().method() === 'POST') {
                await route.fulfill({
                    status: 201,
                    contentType: 'application/json',
                    body: JSON.stringify({
                        id: 1,
                        tenant_id: 1,
                        municipality_id: 1,
                        fiscal_year_id: 1,
                        status: 'queued',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    }),
                });
            }
        });
        
        await page.goto('/frontend/calculations/new');
        
        // フォームに入力
        await page.locator('#municipality_id').fill('1');
        await page.locator('#fiscal_year_id').fill('1');
        
        // 作成ボタンをクリック
        await page.getByRole('button', { name: '作成' }).click();
        
        // 一覧ページにリダイレクト
        await expect(page).toHaveURL('/frontend/calculations');
    });

    test('待機中の計算を実行できる（モック）', async ({ page }) => {
        // 計算一覧APIをモック
        await page.route('**/api/v1/calculation_runs?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        municipality_id: 1,
                        fiscal_year_id: 1,
                        status: 'queued',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                ]),
            });
        });
        
        // 実行APIをモック
        await page.route('**/api/v1/calculation_runs/1/execute', async (route) => {
            await route.fulfill({
                status: 200,
            });
        });
        
        await page.goto('/frontend/calculations');
        
        // 実行ボタンをクリック（確認ダイアログを自動承認、アラートを自動承認）
        page.on('dialog', dialog => dialog.accept());
        await page.getByRole('button', { name: '実行' }).click();
        
        // アラートが表示されるまで待つ
        await page.waitForTimeout(500);
    });

    test('成功した計算の結果を表示できる（モック）', async ({ page }) => {
        // 計算一覧APIをモック
        await page.route('**/api/v1/calculation_runs?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        municipality_id: 1,
                        fiscal_year_id: 1,
                        status: 'succeeded',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                ]),
            });
        });
        
        // 計算詳細APIをモック
        await page.route('**/api/v1/calculation_runs/1?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({
                    id: 1,
                    tenant_id: 1,
                    municipality_id: 1,
                    fiscal_year_id: 1,
                    status: 'succeeded',
                    created_at: '2025-01-01T00:00:00Z',
                    updated_at: '2025-01-01T00:00:00Z',
                }),
            });
        });
        
        // 計算結果APIをモック
        await page.route('**/api/v1/calculation_runs/1/results*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        property_id: 1,
                        property_name: 'テスト資産1',
                        tax_amount: 140000,
                        breakdown: {
                            assessed_value: 10000000,
                            tax_base_value: 10000000,
                            tax_rate: 0.014,
                            tax_amount: 140000,
                        },
                    },
                    {
                        id: 2,
                        property_id: 2,
                        property_name: 'テスト資産2',
                        tax_amount: 70000,
                        breakdown: {
                            assessed_value: 5000000,
                            tax_base_value: 5000000,
                            tax_rate: 0.014,
                            tax_amount: 70000,
                        },
                    },
                ]),
            });
        });
        
        await page.goto('/frontend/calculations');
        
        // 結果を見るリンクをクリック
        await page.getByRole('link', { name: '結果を見る' }).click();
        
        // 結果ページに遷移
        await expect(page).toHaveURL('/frontend/calculations/1/results');
        await expect(page.getByRole('heading', { name: '税額計算結果' })).toBeVisible();
        
        // 合計税額を確認
        await expect(page.getByText('¥210,000')).toBeVisible();
        
        // 個別の結果を確認
        await expect(page.getByText('テスト資産1')).toBeVisible();
        await expect(page.getByText('テスト資産2')).toBeVisible();
        await expect(page.getByText('¥140,000')).toBeVisible();
        await expect(page.getByText('¥70,000')).toBeVisible();
    });

    test('結果ページから一覧に戻れる（モック）', async ({ page }) => {
        // 計算詳細APIをモック
        await page.route('**/api/v1/calculation_runs/1?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({
                    id: 1,
                    tenant_id: 1,
                    municipality_id: 1,
                    fiscal_year_id: 1,
                    status: 'succeeded',
                    created_at: '2025-01-01T00:00:00Z',
                    updated_at: '2025-01-01T00:00:00Z',
                }),
            });
        });
        
        // 計算結果APIをモック
        await page.route('**/api/v1/calculation_runs/1/results*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        // 一覧APIをモック
        await page.route('**/api/v1/calculation_runs?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/calculations/1/results');
        
        // 一覧に戻るボタンをクリック
        await page.getByRole('link', { name: '一覧に戻る' }).click();
        
        // 一覧ページに遷移
        await expect(page).toHaveURL('/frontend/calculations');
    });
});
