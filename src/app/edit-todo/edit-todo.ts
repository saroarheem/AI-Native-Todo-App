import { Component, inject, OnInit } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Data } from '../services/data';

@Component({
  selector: 'app-edit-todo',
  imports: [ReactiveFormsModule],
  templateUrl: './edit-todo.html',
  styleUrl: './edit-todo.css',
})
export class EditTodo implements OnInit {
  constructor(private route: ActivatedRoute, private router: Router) {}
  private formBuilder = inject(FormBuilder);
  private data = inject(Data);
  ngOnInit() {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    const todo = this.data.getTodoById(id);

    if (todo) {
      this.form.patchValue({
        title: todo.title,
        description: todo.description,
        status:todo.status
      });
    }
  }

  form = this.formBuilder.group({
    title: [''],
    description: [''],
    status:['']
  });

  todoid!: number;
  onSubmit() {
    const formData = this.form.getRawValue();

    this.data.updateTodo(
      this.todoid = Number(this.route.snapshot.paramMap.get('id')),
      formData.title ?? '',
      formData.description ?? '',
      formData.status ?? ''
    );
    this.form.reset();
    this.router.navigateByUrl('/list')
  }
}
