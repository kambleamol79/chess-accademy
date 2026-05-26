import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { DashboardMetrics, DashboardService, DashboardStatCard } from 'src/app/core/services/dashboard.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { CoachSchedulePayload } from 'src/app/core/services/coach.service';
import { HttpErrorResponse } from '@angular/common/http';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApexOptions } from 'ng-apexcharts';

export interface ScheduleCell {
  label: string;
  tone: 'blue' | 'beige' | 'practice' | 'empty';
}

const CHART_COLORS = ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#14b8a6'];

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, CardComponent, NgApexchartsModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private readonly dashboard = inject(DashboardService);
  private readonly auth = inject(AuthService);

  metrics = signal<DashboardMetrics | null>(null);
  coachSchedule = signal<CoachSchedulePayload | null>(null);

  loading = signal(true);
  error = signal('');

  statCards = computed(() => {
    const m = this.metrics();
    if (!m) {
      return [];
    }
    return this.buildStatCards(m);
  });

  enrollmentChart = computed(() => this.buildEnrollmentChart(this.metrics()));
  overviewChart = computed(() => this.buildOverviewChart(this.metrics()));
  revenueChart = computed(() => this.buildRevenueChart(this.metrics()));
  invoiceChart = computed(() => this.buildInvoiceChart(this.metrics()));

  ngOnInit() {
    if (this.auth.hasRole(['coach'])) {
      this.dashboard.getCoachSchedule().subscribe({
        next: (res) => {
          this.coachSchedule.set(res.data);
          this.loading.set(false);
          this.error.set('');
        },
        error: (err: HttpErrorResponse) => {
          this.error.set(getApiErrorMessage(err, 'Could not load assigned batches. Is the API running?'));
          this.loading.set(false);
        }
      });
      return;
    }

    this.dashboard.getMetrics().subscribe({
      next: (res) => {
        const data = res.data;
        this.metrics.set({
          ...data,
          revenue_by_month: data.revenue_by_month ?? [],
          invoice_by_status: data.invoice_by_status ?? []
        });
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Could not load dashboard. Is the API running?');
        this.loading.set(false);
      }
    });
  }

  headerName(): string {
    const s = this.coachSchedule();
    if (s?.coach.display_name) {
      return `${s.coach.display_name} SIR`;
    }
    return 'COACH';
  }

  days(): string[] {
    return this.coachSchedule()?.days ?? ['MON', 'TUE', 'WED', 'THUR', 'FRI', 'SAT'];
  }

  timeSlots(): string[] {
    return this.coachSchedule()?.time_slots ?? [];
  }

  cell(time: string, day: string): ScheduleCell {
    const assignments = this.coachSchedule()?.assignments ?? [];
    const match = assignments.find((a) => a.time === time && a.day === day);
    if (!match) {
      return { label: '', tone: 'empty' };
    }
    return {
      label: match.label,
      tone: match.is_practice ? 'practice' : match.highlight
    };
  }

  cellClass(cell: ScheduleCell): string {
    if (cell.tone === 'empty') {
      return 'coach-schedule__cell--empty';
    }
    if (cell.tone === 'practice') {
      return 'coach-schedule__cell--practice';
    }
    if (cell.tone === 'blue') {
      return 'coach-schedule__cell--blue';
    }
    return 'coach-schedule__cell--beige';
  }

  private buildStatCards(m: DashboardMetrics): DashboardStatCard[] {
    return [
      {
        label: 'Students',
        value: String(m.total_students),
        icon: 'ti ti-users',
        cardClass: 'dashboard-stat dashboard-stat--primary',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--primary'
      },
      {
        label: 'Coaches',
        value: String(m.coaches_count),
        icon: 'ti ti-user-star',
        cardClass: 'dashboard-stat dashboard-stat--secondary',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--secondary'
      },
      {
        label: 'Active batches',
        value: String(m.active_batches),
        icon: 'ti ti-calendar-event',
        cardClass: 'dashboard-stat dashboard-stat--success',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--success'
      },
      {
        label: 'Enrollments',
        value: String(m.active_enrollments),
        icon: 'ti ti-school',
        cardClass: 'dashboard-stat dashboard-stat--info',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--info'
      },
      {
        label: 'Revenue this month',
        value: `₹${Math.round(m.revenue_this_month).toLocaleString('en-IN')}`,
        icon: 'ti ti-currency-rupee',
        cardClass: 'dashboard-stat dashboard-stat--warning',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--warning'
      },
      {
        label: 'Pending invoices',
        value: String(m.pending_invoices),
        icon: 'ti ti-receipt',
        cardClass: 'dashboard-stat dashboard-stat--danger',
        iconClass: 'dashboard-stat__icon dashboard-stat__icon--danger'
      }
    ];
  }

  private buildEnrollmentChart(m: DashboardMetrics | null): Partial<ApexOptions> | null {
    if (!m?.enrollment_by_batch?.length) {
      return null;
    }

    const rows = m.enrollment_by_batch;
    const categories = rows.map((r) => r.batch);
    const data = rows.map((r) => Number(r.enrolled));

    return {
      chart: { type: 'bar', height: 320, toolbar: { show: false }, fontFamily: 'inherit' },
      colors: categories.map((_, i) => CHART_COLORS[i % CHART_COLORS.length]),
      plotOptions: {
        bar: {
          borderRadius: 8,
          columnWidth: '55%',
          distributed: true
        }
      },
      dataLabels: { enabled: false },
      legend: { show: false },
      series: [{ name: 'Enrolled', data }],
      xaxis: {
        categories,
        labels: { rotate: -35, trim: true, style: { fontSize: '11px' } }
      },
      yaxis: {
        labels: { formatter: (v) => `${Math.round(v)}` },
        title: { text: 'Students' }
      },
      grid: { strokeDashArray: 4 },
      tooltip: { theme: 'light' }
    };
  }

  private buildOverviewChart(m: DashboardMetrics | null): Partial<ApexOptions> | null {
    if (!m) {
      return null;
    }

    const series = [m.total_students, m.coaches_count, m.active_batches, m.active_enrollments];
    if (series.every((v) => v === 0)) {
      return null;
    }

    return {
      chart: { type: 'donut', height: 300, fontFamily: 'inherit' },
      colors: CHART_COLORS.slice(0, 4),
      labels: ['Students', 'Coaches', 'Batches', 'Enrollments'],
      series,
      legend: { position: 'bottom', fontSize: '13px' },
      dataLabels: { enabled: true },
      plotOptions: {
        pie: {
          donut: {
            size: '62%',
            labels: {
              show: true,
              total: {
                show: true,
                label: 'Total',
                formatter: () => `${series.reduce((a, b) => a + b, 0)}`
              }
            }
          }
        }
      },
      tooltip: { theme: 'light' }
    };
  }

  private buildRevenueChart(m: DashboardMetrics | null): Partial<ApexOptions> | null {
    const rows = m?.revenue_by_month ?? [];
    if (rows.length === 0) {
      return null;
    }

    return {
      chart: { type: 'area', height: 320, toolbar: { show: false }, fontFamily: 'inherit', sparkline: { enabled: false } },
      colors: ['#22c55e'],
      fill: {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.45,
          opacityTo: 0.05,
          stops: [0, 90, 100]
        }
      },
      stroke: { curve: 'smooth', width: 3 },
      dataLabels: { enabled: false },
      series: [{ name: 'Revenue', data: rows.map((r) => r.amount) }],
      xaxis: {
        categories: rows.map((r) => r.month),
        labels: { style: { fontSize: '11px' } }
      },
      yaxis: {
        labels: {
          formatter: (v) => `₹${Math.round(v).toLocaleString('en-IN')}`
        }
      },
      grid: { strokeDashArray: 4 },
      tooltip: {
        theme: 'light',
        y: { formatter: (v) => `₹${Math.round(v).toLocaleString('en-IN')}` }
      }
    };
  }

  private buildInvoiceChart(m: DashboardMetrics | null): Partial<ApexOptions> | null {
    const rows = m?.invoice_by_status ?? [];
    if (rows.length === 0) {
      return null;
    }

    const statusLabels: Record<string, string> = {
      pending: 'Pending',
      paid: 'Paid',
      overdue: 'Overdue'
    };
    const statusColors: Record<string, string> = {
      pending: '#f59e0b',
      paid: '#22c55e',
      overdue: '#ef4444'
    };

    return {
      chart: { type: 'donut', height: 300, fontFamily: 'inherit' },
      labels: rows.map((r) => statusLabels[r.status] ?? r.status),
      colors: rows.map((r) => statusColors[r.status] ?? '#94a3b8'),
      series: rows.map((r) => Number(r.count)),
      legend: { position: 'bottom', fontSize: '13px' },
      dataLabels: { enabled: true },
      plotOptions: {
        pie: {
          donut: { size: '58%' }
        }
      },
      tooltip: { theme: 'light' }
    };
  }
}
