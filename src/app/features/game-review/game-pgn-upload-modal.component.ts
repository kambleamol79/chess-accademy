import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { GameService } from 'src/app/core/services/game.service';
import { StudentService } from 'src/app/core/services/student.service';
import { studentDisplayName } from 'src/app/core/models/game.model';
import { parsePgn } from 'src/app/core/utils/pgn.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-game-pgn-upload-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './game-pgn-upload-modal.component.html',
  styleUrl: './game-pgn-upload-modal.component.scss'
})
export class GamePgnUploadModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly games = inject(GameService);
  private readonly students = inject(StudentService);

  loadingStudents = signal(true);
  saving = signal(false);
  error = signal('');
  fileName = signal('');

  studentOptions = signal<Record<string, unknown>[]>([]);
  studentId: number | null = null;
  title = '';
  notes = '';
  pgnText = '';

  moveCount = signal(0);
  pgnValid = signal(false);
  pgnPreviewError = signal('');

  ngOnInit(): void {
    this.students.list().subscribe({
      next: (res) => {
        this.studentOptions.set(res.data ?? []);
        this.loadingStudents.set(false);
      },
      error: () => {
        this.error.set('Could not load students');
        this.loadingStudents.set(false);
      }
    });
  }

  studentLabel(row: Record<string, unknown>): string {
    return studentDisplayName(row);
  }

  dismiss(): void {
    this.activeModal.dismiss();
  }

  onPgnInput(): void {
    this.validatePgn();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) {
      return;
    }

    this.error.set('');
    this.fileName.set(file.name);

    const reader = new FileReader();
    reader.onload = () => {
      this.pgnText = String(reader.result ?? '');
      if (!this.title.trim()) {
        const parsed = parsePgn(this.pgnText);
        if (parsed.suggestedTitle) {
          this.title = parsed.suggestedTitle;
        }
      }
      this.validatePgn();
    };
    reader.onerror = () => this.error.set('Could not read file');
    reader.readAsText(file);
  }

  private validatePgn(): void {
    const result = parsePgn(this.pgnText);
    this.pgnValid.set(result.valid);
    this.moveCount.set(result.moveCount);
    this.pgnPreviewError.set(result.error ?? '');
    if (result.valid && !this.title.trim() && result.suggestedTitle) {
      this.title = result.suggestedTitle;
    }
  }

  save(): void {
    this.error.set('');
    if (!this.studentId) {
      this.error.set('Select a student');
      return;
    }

    const result = parsePgn(this.pgnText);
    if (!result.valid) {
      this.error.set(result.error ?? 'Invalid PGN');
      return;
    }

    this.saving.set(true);
    this.games
      .create({
        student_id: this.studentId,
        pgn: this.pgnText.trim(),
        title: this.title.trim() || undefined,
        notes: this.notes.trim() || undefined
      })
      .subscribe({
        next: () => {
          this.saving.set(false);
          this.activeModal.close(true);
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not save game'));
        }
      });
  }
}
