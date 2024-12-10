import tkinter as tk

def toggle_cell(row, col):
    grid[row][col] = (grid[row][col] - 1) % 3
    color = ["black", "white", "red"][grid[row][col]]
    buttons[row][col].config(bg=color)

def print_grid():
    flat_grid = [cell for row in grid for cell in row]
    print(flat_grid)

rows, cols = 16, 11

grid = [[1 for _ in range(cols)] for _ in range(rows)]

root = tk.Tk()
root.title("11x16 Grid Toggle")

buttons = []

for r in range(rows):
    button_row = []
    for c in range(cols):
        btn = tk.Button(root, width=2, height=1, bg="white", command=lambda r=r, c=c: toggle_cell(r, c))
        btn.grid(row=r, column=c, padx=1, pady=1)
        button_row.append(btn)
    buttons.append(button_row)

print_button = tk.Button(root, text="Print Grid", command=print_grid)
print_button.grid(row=rows, column=0, columnspan=cols)

root.mainloop()
