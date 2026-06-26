import { Component, inject, OnInit } from '@angular/core';
import { Data } from '../services/data';
import { RouterLink } from "@angular/router";

@Component({
  selector: 'app-todo-list',
  imports: [RouterLink],
  templateUrl: './todo-list.html',
  styleUrl: './todo-list.css',
})
export class TodoList{

  private data = inject(Data)
  arr: any = this.data.getUsers();


  delete(todoid:any){
    let itemIndex = this.data.todos.findIndex((obj)=>{
      return obj.id == todoid;
    })
    this.data.todos.splice(itemIndex,1);
  }

  







}
