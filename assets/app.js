import { h, render } from 'https://unpkg.com/preact@latest?module';
import { useState, useEffect } from 'https://unpkg.com/preact@latest/hooks/dist/hooks.module.js?module';
import htm from 'https://unpkg.com/htm@3.1.1/dist/htm.module.js?module';
const html = htm.bind(h);

const api = {
  getTodos: async () => {
    const res = await fetch('/todos');
    if (!res.ok) {
      throw new HTTPError(`Error: ${res.statusText}`);
    }
    return await res.json();
  },
  postTodo: async (todo) => {
    const res = await fetch('/todos', {
      method: 'POST',
      body: JSON.stringify(todo),
      headers: { 'Content-Type': 'application/json' },
    });
    if (!res.ok) {
      throw new HTTPError(`Error: ${res.statusText}`);
    }
    return await res.json();
  },
  putTodo: async (todo) => {
    const res = await fetch(`/todos/${todo.id}`, {
      method: 'PUT',
      body: JSON.stringify(todo),
      headers: { 'Content-Type': 'application/json' },
    });
    if (!res.ok) {
      throw new HTTPError(`Error: ${res.statusText}`);
    }
    return await res.json();
  },
  deleteTodo: async (todo) => {
    const res = await fetch(`/todos/${todo.id}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      throw new HTTPError(`Error: ${res.statusText}`);
    }
    return await res.json();
  },
};

const App = () => {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState('');

  useEffect(() => {
    api
      .getTodos()
      .then(res => setTodos(res));
  }, [api, setTodos]);

  const handleChange = (e) => setNewTodo(e.target.value);
  const handleClick = () => {
    if (newTodo !== '') {
      const title = newTodo;
      api
        .postTodo({ title, completed: false })
        .then((res) => {
          setTodos([...todos, res]);
          setNewTodo('');
        });
    }
  };
  const toggleTodo = (todo) => {
    const toggled = {
      ...todo,
      completed: !todo.completed,
    };
    api
      .putTodo(toggled)
      .then(() => {
        setTodos([...todos.map((t) => t.id !== todo.id ? t : toggled)]);
      });
  };
  const deleteTodo = (todo) => {
    api
      .deleteTodo(todo)
      .then(() => {
        setTodos([...todos.filter(({ id }) => id !== todo.id)]);
      });
  };

  return html`
    <div className="container">
      <h1>ToDos</h1>
      <div className="new-todo">
        <input
          type="text"
          value=${newTodo}
          onChange=${handleChange}
          className="new-todo-input"
          placeholder="What should be done?"
        />
        <button onClick=${handleClick} className="new-todo-btn">Add</button>
      </div>
      <${TodoList} todos=${todos} toggleTodo=${toggleTodo} deleteTodo=${deleteTodo} />
    </div>
  `;
}

const TodoList = ({ todos, toggleTodo, deleteTodo }) => html`
  <ul className="todo-list">
    ${todos.map((todo) => html`
      <${TodoItem} key=${todo.id} todo=${todo} toggleTodo=${() => toggleTodo(todo)} deleteTodo=${() => deleteTodo(todo)} />
    `)}
  </ul>
`;

const TodoItem = ({ todo, toggleTodo, deleteTodo }) => {
  return html`
    <li className="todo-list-item">
      <input type="checkbox" checked=${todo.completed} onChange=${toggleTodo} />
      <span className=${"todo-list-item-text" + (todo.completed ? " checked" : "")}>${todo.title}</span>
      <button onClick=${deleteTodo}>Delete</button>
    </li>
  `;
};

render(html`<${App} />`, document.body);
