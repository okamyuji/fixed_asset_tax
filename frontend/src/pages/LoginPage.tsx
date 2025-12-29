import { zodResolver } from '@hookform/resolvers/zod';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { authApi } from '../api/auth';
import { useAuthStore } from '../stores/authStore';

const loginSchema = z.object({
    email: z.string().email('有効なメールアドレスを入力してください'),
    password: z.string().min(1, 'パスワードを入力してください'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export const LoginPage = () => {
    const navigate = useNavigate();
    const setAuth = useAuthStore((state) => state.setAuth);
    const [error, setError] = useState<string>('');
    const [isLoading, setIsLoading] = useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<LoginFormData>({
        resolver: zodResolver(loginSchema),
    });

    const onSubmit = async (data: LoginFormData) => {
        setIsLoading(true);
        setError('');

        try {
            const response = await authApi.login(data);
            // TODO: テナントIDの取得方法を確認
            // 現在はダミーで"1"を設定
            setAuth(response.token, '1');
            navigate('/');
        } catch (err) {
            setError('ログインに失敗しました。メールアドレスとパスワードを確認してください。');
            console.error('Login error:', err);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
            <div className="max-w-md w-full">
                <div className="bg-white rounded-lg border border-gray-200 p-8 space-y-6">
                    {/* ヘッダー */}
                    <div className="text-center space-y-2">
                        <div className="inline-flex items-center justify-center w-12 h-12 bg-blue-100 rounded-lg mb-4">
                            <span className="text-2xl">🏢</span>
                        </div>
                        <h2 className="text-2xl font-bold text-gray-900">
                            固定資産税計算システム
                        </h2>
                        <p className="text-sm text-gray-600">
                            アカウントにログイン
                        </p>
                    </div>

                    {/* フォーム */}
                    <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
                        {/* メールアドレス */}
                        <div>
                            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1.5">
                                メールアドレス
                            </label>
                            <input
                                {...register('email')}
                                id="email"
                                type="email"
                                autoComplete="email"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="your@email.com"
                            />
                            {errors.email && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.email.message}
                                </p>
                            )}
                        </div>

                        {/* パスワード */}
                        <div>
                            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1.5">
                                パスワード
                            </label>
                            <input
                                {...register('password')}
                                id="password"
                                type="password"
                                autoComplete="current-password"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="パスワードを入力"
                            />
                            {errors.password && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.password.message}
                                </p>
                            )}
                        </div>

                        {/* エラーメッセージ */}
                        {error && (
                            <div className="rounded-md bg-red-50 border border-red-200 p-3">
                                <p className="text-sm text-red-800">{error}</p>
                            </div>
                        )}

                        {/* ログインボタン */}
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="w-full flex justify-center items-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                            {isLoading ? 'ログイン中...' : 'ログイン'}
                        </button>
                    </form>

                    {/* 新規登録リンク */}
                    <div className="text-center pt-4 border-t border-gray-200">
                        <p className="text-sm text-gray-600">
                            アカウントをお持ちでない方は{' '}
                            <Link
                                to="/register"
                                className="font-medium text-blue-600 hover:text-blue-500"
                            >
                                新規登録
                            </Link>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};
