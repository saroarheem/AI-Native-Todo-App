import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { Data } from '../services/data';
import { Router } from '@angular/router';

@Component({
  selector: 'app-create-todo',
  imports: [ReactiveFormsModule],
  templateUrl: './create-todo.html',
  styleUrl: './create-todo.css',
})
export class CreateTodo {
  private formBuilder = inject(FormBuilder);
  private router = inject(Router)
  private data = inject(Data)

  form = this.formBuilder.group({
    title:[''],
    description:[''],
    status:['due']
  });

  

  onSubmit(){

    const formData = this.form.getRawValue();
    let todoLength = this.data.todos.length;
    const newTodo = {
      id: this.data.todos[todoLength-1].id + 1,
      title: formData.title??'',
      description: formData.description??'',
      status: formData.status??'due',
    };
    this.data.addTodo(newTodo);
    this.form.reset();
    this.router.navigateByUrl('/list')
  }
}
