import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { BrowserRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as useCalculationsHook from "../../hooks/useCalculations";
import { CalculationsPage } from "../CalculationsPage";

const mockCalculationRuns = [
	{
		id: 1,
		tenant_id: 1,
		municipality_id: 1,
		fiscal_year_id: 1,
		status: "queued" as const,
		created_at: "2025-01-01T00:00:00Z",
		updated_at: "2025-01-01T00:00:00Z",
	},
	{
		id: 2,
		tenant_id: 1,
		municipality_id: 1,
		fiscal_year_id: 1,
		status: "succeeded" as const,
		created_at: "2025-01-02T00:00:00Z",
		updated_at: "2025-01-02T00:00:00Z",
	},
];

const createWrapper = () => {
	const queryClient = new QueryClient({
		defaultOptions: {
			queries: { retry: false },
			mutations: { retry: false },
		},
	});
	return ({ children }: { children: React.ReactNode }) => (
		<QueryClientProvider client={queryClient}>
			<BrowserRouter>{children}</BrowserRouter>
		</QueryClientProvider>
	);
};

describe("CalculationsPage", () => {
	beforeEach(() => {
		vi.clearAllMocks();
	});

	it("renders calculation runs list", () => {
		vi.spyOn(useCalculationsHook, "useCalculations").mockReturnValue({
			calculationRuns: mockCalculationRuns,
			isLoading: false,
			error: null,
			createCalculationRun: vi.fn(),
			executeCalculationRun: vi.fn(),
			isCreating: false,
			isExecuting: false,
		});

		render(<CalculationsPage />, { wrapper: createWrapper() });

		expect(screen.getByText("税額計算")).toBeInTheDocument();
		expect(screen.getByText("待機中")).toBeInTheDocument();
		expect(screen.getByText("成功")).toBeInTheDocument();
	});

	it("shows loading state", () => {
		vi.spyOn(useCalculationsHook, "useCalculations").mockReturnValue({
			calculationRuns: [],
			isLoading: true,
			error: null,
			createCalculationRun: vi.fn(),
			executeCalculationRun: vi.fn(),
			isCreating: false,
			isExecuting: false,
		});

		render(<CalculationsPage />, { wrapper: createWrapper() });

		expect(screen.getByText("読み込み中...")).toBeInTheDocument();
	});

	it("shows empty state when no calculation runs", () => {
		vi.spyOn(useCalculationsHook, "useCalculations").mockReturnValue({
			calculationRuns: [],
			isLoading: false,
			error: null,
			createCalculationRun: vi.fn(),
			executeCalculationRun: vi.fn(),
			isCreating: false,
			isExecuting: false,
		});

		render(<CalculationsPage />, { wrapper: createWrapper() });

		expect(screen.getByText("計算履歴がありません")).toBeInTheDocument();
	});

	it("calls execute function when execute button clicked", async () => {
		const user = userEvent.setup();
		const mockExecute = vi.fn().mockResolvedValue(undefined);

		vi.spyOn(useCalculationsHook, "useCalculations").mockReturnValue({
			calculationRuns: mockCalculationRuns,
			isLoading: false,
			error: null,
			createCalculationRun: vi.fn(),
			executeCalculationRun: mockExecute,
			isCreating: false,
			isExecuting: false,
		});

		vi.spyOn(window, "confirm").mockReturnValue(true);
		vi.spyOn(window, "alert").mockImplementation(() => {});

		render(<CalculationsPage />, { wrapper: createWrapper() });

		const executeButton = screen.getByText("実行");
		await user.click(executeButton);

		await waitFor(() => {
			expect(mockExecute).toHaveBeenCalledWith(1);
		});
	});
});
