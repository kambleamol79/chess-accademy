import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { StudentService } from 'src/app/core/services/student.service';

@Component({
  selector: 'app-students',
  imports: [CommonModule, CardComponent],
  templateUrl: './students.component.html',
  styleUrl: './students.component.scss'
})
export class StudentsComponent implements OnInit {
  private readonly students = inject(StudentService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.students.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load students');
        this.loading.set(false);
      }
    });
  }
}
