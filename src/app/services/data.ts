import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class Data {
  todos: SingleTodo[] = [
    {
      id: 1,
      title: 'Learn Html',
      description: 'I have to learn html in order to learn angular',
      status: "done"
    },
    {
      id: 2,
      title: 'Learn Css',
      description: 'I have to learn css in order to learn angular',
      status: "due"
    },
    {
      id: 3,
      title: 'Learn js',
      description: 'I have to learn js in order to learn angular',
      status: "done"
    },
    {
      id: 4,
      title: 'Learn array',
      description: 'I have to learn array in order to learn angular',
      status: "due"
    }
  ];

  addTodo(todo: SingleTodo) {
    this.todos.push(todo);
  }

  getTodos() {
    return this.todos;
  }

  getTodoById(id: number): SingleTodo | undefined {
  return this.todos.find(todo => todo.id === id);
}

  updateTodo(id:number, title:string, description:string, status:string){
    let todo = this.todos.find(x => x.id == id)

    if(todo){
        todo.title = title;
        todo.description = description;
        todo.status = status;
    }
  }

}

export interface SingleTodo {
  id: number;
  title: string;
  description: string;
  status:string
}

// class SingleTodo {
//   id: any;
//   title: string;
//   description: any;

//   constructor(id: any, title: string, description: any) {
//     this.id = id;
//     this.title = title;
//     this.description = description;
//   }
// }