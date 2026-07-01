import { Routes } from '@angular/router';
import { CreateTodo } from './create-todo/create-todo';
import { TodoList } from './todo-list/todo-list';
import { EditTodo } from './edit-todo/edit-todo';
import { PageNotFound } from './page-not-found/page-not-found';

export const routes: Routes = [
    {path: "list", component: TodoList},
    {path: "create", component: CreateTodo},
    {path: "todo/:id", component: EditTodo},
    {path: "", redirectTo:"list", pathMatch: "full"},
    {path: "**", component: PageNotFound},
];
