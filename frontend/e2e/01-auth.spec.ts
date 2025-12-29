import { expect, test } from '@playwright/test';

test.describe('認証フロー', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/frontend/');
    });

    test('ログインページが表示される', async ({ page }) => {
        // ログインページにリダイレクトされることを確認
        await expect(page).toHaveURL('/frontend/login');

        // ページタイトルを確認
        await expect(page.getByText('固定資産税計算システム')).toBeVisible();
        await expect(page.getByText('アカウントにログイン')).toBeVisible();

        // フォーム要素を確認
        await expect(page.getByPlaceholder('your@email.com')).toBeVisible();
        await expect(page.getByPlaceholder('パスワードを入力')).toBeVisible();
        await expect(page.getByRole('button', { name: 'ログイン' })).toBeVisible();
    });

    test('空のフォームでバリデーションエラーが表示される', async ({ page }) => {
        await page.goto('/frontend/login');
        
        // ログインボタンをクリック
        await page.getByRole('button', { name: 'ログイン' }).click();
        
        // バリデーションエラーを確認
        await expect(page.getByText('有効なメールアドレスを入力してください')).toBeVisible();
        await expect(page.getByText('パスワードを入力してください')).toBeVisible();
    });

    test('無効なメールアドレスでバリデーションエラーが表示される', async ({ page }) => {
        await page.goto('/frontend/login');

        // 無効なメールアドレスを入力
        const emailInput = page.getByPlaceholder('your@email.com');
        await emailInput.fill('invalid-email');
        await page.getByPlaceholder('パスワードを入力').fill('password123');
        
        // ログインボタンをクリック
        await page.getByRole('button', { name: 'ログイン' }).click();
        
        // バリデーションエラーを確認
        // HTML5のバリデーションメッセージまたはReact Hook Formのエラーメッセージを確認
        const validationMessage = await emailInput.evaluate((el: HTMLInputElement) => el.validationMessage);
        expect(validationMessage).toBeTruthy();
    });

    test('正しい認証情報でログインできる（モック）', async ({ page }) => {
        // APIリクエストをモック（page.gotoの前に設定）
        await page.route('**/api/v1/auth/login', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ token: 'mock-jwt-token' }),
            });
        });

        await page.goto('/frontend/login');

        // 認証情報を入力
        await page.getByPlaceholder('your@email.com').fill('test@example.com');
        await page.getByPlaceholder('パスワードを入力').fill('password123');

        // ログインボタンをクリック
        await page.getByRole('button', { name: 'ログイン' }).click();

        // ダッシュボードにリダイレクトされることを確認
        await expect(page).toHaveURL('/frontend');
        await expect(page.getByRole('heading', { name: 'ダッシュボード' })).toBeVisible();
    });

    test('間違った認証情報でエラーメッセージが表示される（モック）', async ({ page }) => {
        // APIリクエストをモック（エラー）（page.gotoの前に設定）
        await page.route('**/api/v1/auth/login', async (route) => {
            await route.abort('failed');
        });

        await page.goto('/frontend/login');

        // 認証情報を入力
        await page.getByPlaceholder('your@email.com').fill('test@example.com');
        await page.getByPlaceholder('パスワードを入力').fill('wrong-password');

        // ログインボタンをクリック
        await page.getByRole('button', { name: 'ログイン' }).click();

        // エラーメッセージを確認（少し待つ）
        await page.waitForTimeout(1000);
        await expect(page.getByText(/ログインに失敗しました/)).toBeVisible();
    });

    test('ログイン後、ログアウトできる（モック）', async ({ page }) => {
        // ログインAPIをモック（page.gotoの前に設定）
        await page.route('**/api/v1/auth/login', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ token: 'mock-jwt-token' }),
            });
        });
        
        await page.goto('/frontend/login');
        
        // ログイン
        await page.getByPlaceholder('your@email.com').fill('test@example.com');
        await page.getByPlaceholder('パスワードを入力').fill('password123');
        await page.getByRole('button', { name: 'ログイン' }).click();
        
        // ダッシュボードに移動
        await expect(page).toHaveURL('/frontend');
        
        // ログアウトボタンをクリック
        await page.getByRole('button', { name: 'ログアウト' }).click();
        
        // ログインページにリダイレクトされることを確認
        await expect(page).toHaveURL('/frontend/login');
    });
});
