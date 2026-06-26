import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EditTodo } from './edit-todo';

describe('EditTodo', () => {
  let component: EditTodo;
  let fixture: ComponentFixture<EditTodo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [EditTodo],
    }).compileComponents();

    fixture = TestBed.createComponent(EditTodo);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
