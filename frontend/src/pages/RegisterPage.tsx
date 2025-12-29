import { zodResolver } from '@hookform/resolvers/zod';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { z } from 'zod';
import { authApi } from '../api/auth';
import { useAuthStore } from '../stores/authStore';

const registerSchema = z.object({
    tenant_name: z.string().min(1, 'テナント名を入力してください'),
    name: z.string().min(1, '氏名を入力してください'),
    email: z.string().email('有効なメールアドレスを入力してください'),
    password: z.string().min(8, 'パスワードは8文字以上で入力してください'),
    password_confirmation: z.string().min(1, 'パスワード（確認）を入力してください'),
}).refine((data) => data.password === data.password_confirmation, {
    message: 'パスワードが一致しません',
    path: ['password_confirmation'],
});

type RegisterFormData = z.infer<typeof registerSchema>;

export const RegisterPage = () => {
    const navigate = useNavigate();
    const setAuth = useAuthStore((state) => state.setAuth);
    const [error, setError] = useState<string>('');
    const [isLoading, setIsLoading] = useState(false);

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<RegisterFormData>({
        resolver: zodResolver(registerSchema),
    });

    const onSubmit = async (data: RegisterFormData) => {
        setIsLoading(true);
        setError('');

        try {
            const response = await authApi.register(data);
            setAuth(response.token, response.tenant_id);
            navigate('/');
        } catch (err: unknown) {
            if (err instanceof Error) {
                setError(err.message || '登録に失敗しました。入力内容を確認してください。');
            } else {
                setError('登録に失敗しました。入力内容を確認してください。');
            }
            console.error('Register error:', err);
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
                            新規登録
                        </h2>
                        <p className="text-sm text-gray-600">
                            テナントとアカウントを作成
                        </p>
                    </div>

                    {/* フォーム */}
                    <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
                        {/* テナント名 */}
                        <div>
                            <label htmlFor="tenant_name" className="block text-sm font-medium text-gray-700 mb-1.5">
                                テナント名（会社名・組織名）
                            </label>
                            <input
                                {...register('tenant_name')}
                                id="tenant_name"
                                type="text"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="株式会社サンプル"
                            />
                            {errors.tenant_name && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.tenant_name.message}
                                </p>
                            )}
                        </div>

                        {/* ユーザー名 */}
                        <div>
                            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1.5">
                                氏名
                            </label>
                            <input
                                {...register('name')}
                                id="name"
                                type="text"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="山田 太郎"
                            />
                            {errors.name && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.name.message}
                                </p>
                            )}
                        </div>

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
                                autoComplete="new-password"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="8文字以上"
                            />
                            {errors.password && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.password.message}
                                </p>
                            )}
                        </div>

                        {/* パスワード（確認） */}
                        <div>
                            <label htmlFor="password_confirmation" className="block text-sm font-medium text-gray-700 mb-1.5">
                                パスワード（確認）
                            </label>
                            <input
                                {...register('password_confirmation')}
                                id="password_confirmation"
                                type="password"
                                autoComplete="new-password"
                                className="block w-full px-3 py-2.5 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                                placeholder="パスワードを再入力"
                            />
                            {errors.password_confirmation && (
                                <p className="mt-1.5 text-sm text-red-600">
                                    {errors.password_confirmation.message}
                                </p>
                            )}
                        </div>

                        {/* エラーメッセージ */}
                        {error && (
                            <div className="rounded-md bg-red-50 border border-red-200 p-3">
                                <p className="text-sm text-red-800">{error}</p>
                            </div>
                        )}

                        {/* 登録ボタン */}
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="w-full flex justify-center items-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                            {isLoading ? '登録中...' : '登録'}
                        </button>
                    </form>

                    {/* ログインリンク */}
                    <div className="text-center pt-4 border-t border-gray-200">
                        <p className="text-sm text-gray-600">
                            すでにアカウントをお持ちですか？{' '}
                            <Link
                                to="/login"
                                className="font-medium text-blue-600 hover:text-blue-500"
                            >
                                ログイン
                            </Link>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};
