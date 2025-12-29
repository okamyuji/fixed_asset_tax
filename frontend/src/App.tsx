import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { ProtectedRoute } from './components/ProtectedRoute';
import { CalculationNewPage } from './pages/CalculationNewPage';
import { CalculationResultsPage } from './pages/CalculationResultsPage';
import { CalculationsPage } from './pages/CalculationsPage';
import { DashboardPage } from './pages/DashboardPage';
import { FixedAssetEditPage } from './pages/FixedAssetEditPage';
import { FixedAssetNewPage } from './pages/FixedAssetNewPage';
import { FixedAssetsPage } from './pages/FixedAssetsPage';
import { LoginPage } from './pages/LoginPage';
import { PropertiesPage } from './pages/PropertiesPage';
import { PropertyEditPage } from './pages/PropertyEditPage';
import { PropertyNewPage } from './pages/PropertyNewPage';
import { RegisterPage } from './pages/RegisterPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter basename="/frontend">
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout>
                  <DashboardPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/properties"
            element={
              <ProtectedRoute>
                <Layout>
                  <PropertiesPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/properties/new"
            element={
              <ProtectedRoute>
                <Layout>
                  <PropertyNewPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/properties/:id/edit"
            element={
              <ProtectedRoute>
                <Layout>
                  <PropertyEditPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/fixed-assets"
            element={
              <ProtectedRoute>
                <Layout>
                  <FixedAssetsPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/fixed-assets/new"
            element={
              <ProtectedRoute>
                <Layout>
                  <FixedAssetNewPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/fixed-assets/:id/edit"
            element={
              <ProtectedRoute>
                <Layout>
                  <FixedAssetEditPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/calculations"
            element={
              <ProtectedRoute>
                <Layout>
                  <CalculationsPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/calculations/new"
            element={
              <ProtectedRoute>
                <Layout>
                  <CalculationNewPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/calculations/:id/results"
            element={
              <ProtectedRoute>
                <Layout>
                  <CalculationResultsPage />
                </Layout>
              </ProtectedRoute>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
