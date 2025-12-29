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

test.describe('資産管理CRUD', () => {
    test.beforeEach(async ({ page }) => {
        await login(page);
    });

    test('資産一覧ページに遷移できる', async ({ page }) => {
        // 資産一覧APIをモック
        await page.route('**/api/v1/properties*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        // 直接資産一覧ページに遷移
        await page.goto('/frontend/properties');
        
        // 資産一覧ページが表示される
        await expect(page).toHaveURL('/frontend/properties');
        await expect(page.getByRole('heading', { name: '資産管理', level: 1 })).toBeVisible();
        await expect(page.getByRole('link', { name: '新規登録' })).toBeVisible();
    });

    test('空の資産一覧が表示される', async ({ page }) => {
        // 資産一覧APIをモック（空配列）
        await page.route('**/api/v1/properties*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/properties');
        
        // 空メッセージを確認
        await expect(page.getByText('登録されている資産がありません')).toBeVisible();
    });

    test('資産一覧が表示される', async ({ page }) => {
        // 資産一覧APIをモック
        await page.route('**/api/v1/properties*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        name: 'テスト資産1',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都渋谷区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                    {
                        id: 2,
                        tenant_id: 1,
                        name: 'テスト資産2',
                        property_type: 'depreciable',
                        party_id: 2,
                        municipality_id: 1,
                        address: '東京都新宿区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                ]),
            });
        });
        
        await page.goto('/frontend/properties');
        
        // 資産が表示されることを確認
        await expect(page.getByText('テスト資産1')).toBeVisible();
        await expect(page.getByText('テスト資産2')).toBeVisible();
        await expect(page.getByText('土地')).toBeVisible();
        await expect(page.getByText('償却資産')).toBeVisible();
    });

    test('新規資産作成ページに遷移できる', async ({ page }) => {
        await page.route('**/api/v1/properties*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/properties');
        
        // 新規登録ボタンをクリック
        await page.getByRole('link', { name: '新規登録' }).click();
        
        // 新規作成ページに遷移
        await expect(page).toHaveURL('/frontend/properties/new');
        await expect(page.getByRole('heading', { name: '資産の新規登録' })).toBeVisible();
    });

    test('新規資産を作成できる（モック）', async ({ page }) => {
        await page.route('**/api/v1/properties*', async (route) => {
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
                        name: '新規テスト資産',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都千代田区',
                        notes: 'テスト備考',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    }),
                });
            }
        });
        
        await page.goto('/frontend/properties/new');
        
        // フォームに入力
        await page.getByLabel('資産名').fill('新規テスト資産');
        await page.locator('#property_type').selectOption('land');
        await page.getByLabel('所有者ID').fill('1');
        await page.getByLabel('市区町村ID').fill('1');
        await page.getByLabel('住所').fill('東京都千代田区');
        await page.getByLabel('備考').fill('テスト備考');
        
        // 保存ボタンをクリック
        await page.getByRole('button', { name: '保存' }).click();
        
        // 一覧ページにリダイレクト
        await expect(page).toHaveURL('/frontend/properties');
    });

    test('資産編集ページに遷移できる', async ({ page }) => {
        // 一覧APIをモック
        await page.route('**/api/v1/properties?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        name: 'テスト資産1',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都渋谷区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                ]),
            });
        });
        
        // 詳細APIをモック
        await page.route('**/api/v1/properties/1*', async (route) => {
            if (route.request().method() === 'GET') {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({
                        id: 1,
                        tenant_id: 1,
                        name: 'テスト資産1',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都渋谷区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    }),
                });
            }
        });
        
        await page.goto('/frontend/properties');
        
        // 編集ボタンをクリック
        await page.getByRole('link', { name: '編集' }).first().click();
        
        // 編集ページに遷移
        await expect(page).toHaveURL('/frontend/properties/1/edit');
        await expect(page.getByRole('heading', { name: '資産の編集' })).toBeVisible();
    });

    test('資産を編集できる（モック）', async ({ page }) => {
        // 詳細APIをモック
        await page.route('**/api/v1/properties/1*', async (route) => {
            if (route.request().method() === 'GET') {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({
                        id: 1,
                        tenant_id: 1,
                        name: 'テスト資産1',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都渋谷区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    }),
                });
            } else if (route.request().method() === 'PUT') {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({
                        id: 1,
                        tenant_id: 1,
                        name: '更新されたテスト資産',
                        property_type: 'depreciable',
                        party_id: 2,
                        municipality_id: 2,
                        address: '東京都港区',
                        notes: '更新されました',
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    }),
                });
            }
        });
        
        await page.route('**/api/v1/properties?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]),
            });
        });
        
        await page.goto('/frontend/properties/1/edit');
        
        // フォームを編集
        await page.getByLabel('資産名').fill('更新されたテスト資産');
        await page.locator('#property_type').selectOption('depreciable');
        await page.getByLabel('所有者ID').fill('2');
        await page.getByLabel('市区町村ID').fill('2');
        await page.getByLabel('住所').fill('東京都港区');
        await page.getByLabel('備考').fill('更新されました');
        
        // 保存ボタンをクリック
        await page.getByRole('button', { name: '保存' }).click();
        
        // 一覧ページにリダイレクト
        await expect(page).toHaveURL('/frontend/properties');
    });

    test('資産を削除できる（モック）', async ({ page }) => {
        // 一覧APIをモック
        await page.route('**/api/v1/properties?*', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([
                    {
                        id: 1,
                        tenant_id: 1,
                        name: 'テスト資産1',
                        property_type: 'land',
                        party_id: 1,
                        municipality_id: 1,
                        address: '東京都渋谷区',
                        notes: null,
                        created_at: '2025-01-01T00:00:00Z',
                        updated_at: '2025-01-01T00:00:00Z',
                    },
                ]),
            });
        });
        
        // 削除APIをモック
        await page.route('**/api/v1/properties/1*', async (route) => {
            if (route.request().method() === 'DELETE') {
                await route.fulfill({
                    status: 204,
                });
            }
        });
        
        await page.goto('/frontend/properties');
        
        // 削除ボタンをクリック（確認ダイアログを自動承認）
        page.on('dialog', dialog => dialog.accept());
        await page.getByRole('button', { name: '削除' }).first().click();
        
        // 削除が完了するまで待つ
        await page.waitForTimeout(500);
    });
});
