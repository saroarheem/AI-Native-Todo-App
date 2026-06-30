import { Component, inject, OnInit } from '@angular/core';
import { Data } from '../services/data';
import { RouterLink } from "@angular/router";
import { FormBuilder, ɵInternalFormsSharedModule, ReactiveFormsModule, FormsModule } from '@angular/forms';


@Component({
  selector: 'app-todo-list',
  imports: [RouterLink, ɵInternalFormsSharedModule, ReactiveFormsModule, FormsModule],
  templateUrl: './todo-list.html',
  styleUrl: './todo-list.css',
})
export class TodoList implements OnInit{

  private data = inject(Data)
  private formBuilder = inject(FormBuilder)
  arr: any = this.data.getTodos();


  delete(todoid:any){
    let itemIndex = this.data.todos.findIndex((obj)=>{
      return obj.id == todoid;
    })
    this.data.todos.splice(itemIndex,1);
  }

  // side nav code start 
  
  isSideBarOpen = true;
  toggleSidebar(){
    this.isSideBarOpen = !this.isSideBarOpen;
  }

  form = this.formBuilder.group({
    due:[false],
    done:[false]
  })
  
  onfilter(){
    const selected = Object.entries(this.form.value)
    .filter(([_, checked]) => checked)
    .map(([name]) => name);

    const filteredTodos = this.data.todos.filter((todo)=>{
      return (todo.status == selected[0]) || (todo.status == selected[1])
    })
    this.arr = filteredTodos;

    if(selected.length != 0){
      this.arr = this.data.todos.filter(todo =>
      selected.includes(todo.status)
      );
    }else{
      this.arr = this.data.getTodos();
    }

    // this.arr = this.data.todos.filter(todo =>
    //   selected.includes(todo.status)
    //   );
  }

  ngOnInit(): void {
    this.form.valueChanges.subscribe(() => {
    this.onfilter();
    });

    // this.onfilter();
  }

  
isInitialLoad = true;

ngAfterViewInit() {
  setTimeout(() => {
    this.isInitialLoad = false;
  },0); 
}

// search function
searchText = '';
onSearch(){
  this.arr = this.data.todos.filter(todo=>
    todo.title.toLowerCase().includes(this.searchText.toLowerCase()) ||
    todo.title.toLowerCase().includes(this.searchText.toLowerCase())
  )
}


  // side nav code end

// test start 

// test end 


}
