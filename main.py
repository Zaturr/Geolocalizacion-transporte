import sqlite3
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from dependant import depen
app = FastAPI()
depen.print()
# Database setup (SQLite for simplicity)
def create_connection():
    conn = None
    try:
        conn = sqlite3.connect('users.db')
        return conn
    except sqlite3.Error as e:
        print(e)
    return conn

def create_table():
    conn = create_connection()
    if conn is not None:
        try:
            sql = """ CREATE TABLE IF NOT EXISTS users (
                                        id integer PRIMARY KEY,
                                        username text NOT NULL UNIQUE,
                                        password text NOT NULL
                                    ); """
            c = conn.cursor()
            c.execute(sql)
        except sqlite3.Error as e:
            print(e)
        finally:
            conn.close()

create_table()  # Ensure the table exists on startup.

def insert_user(username, password):
    conn = create_connection()
    if conn is not None:
        try:
            sql = ''' INSERT INTO users(username,password)
                      VALUES(?,?) '''
            cur = conn.cursor()
            cur.execute(sql, (username, password))
            conn.commit()
            return cur.lastrowid
        except sqlite3.Error as e:
            print(e)
            return None  # Indicate failure.
        finally:
            conn.close()

def get_user(username, password):
    conn = create_connection()
    if conn is not None:
        try:
            sql = ''' SELECT * FROM users WHERE username = ? AND password = ?'''
            cur = conn.cursor()
            cur.execute(sql, (username, password))
            return cur.fetchone()
        except sqlite3.Error as e:
            print(e)
            return None  # Indicate failure.
        finally:
            conn.close()

class User(BaseModel):
    username: str
    password: str

@app.post("/register")
def register(user: User):
    if not user.username or not user.password:
        raise HTTPException(status_code=400, detail="Username and password are required")

    if insert_user(user.username, user.password):
        return {"message": "User registered successfully"}
    else:
        raise HTTPException(status_code=400, detail="Username already exists or registration failed")

@app.post("/login")
def login(user: User):
    if not user.username or not user.password:
        raise HTTPException(status_code=400, detail="Username and password are required")

    db_user = get_user(user.username, user.password)

    if db_user:
        return {"message": "Login successful"}
    else:
        raise HTTPException(status_code=401, detail="Invalid username or password")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info") #For production, configure uvicorn properly.