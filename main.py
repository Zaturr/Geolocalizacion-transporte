import sqlite3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

# Database setup (SQLite for simplicity)
DATABASE_NAME = 'transport.db'

def create_connection():
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_NAME)
        return conn
    except sqlite3.Error as e:
        print(e)
    return conn

def create_tables():
    conn = create_connection()
    if conn is not None:
        cursor = conn.cursor()
        try:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    name TEXT,
                    email TEXT,
                    telefono TEXT,
                    contraseña TEXT
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS Admin (
                    id TEXT PRIMARY KEY
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS Conductor (
                    id TEXT PRIMARY KEY
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS Vehiculo (
                    placa TEXT PRIMARY KEY,
                    kilometraje REAL,
                    año INTEGER,
                    modelo TEXT
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS Ruta (
                    id TEXT PRIMARY KEY,
                    autobus TEXT,
                    conductor TEXT,
                    paradas TEXT,
                    FOREIGN KEY (autobus) REFERENCES Vehiculo(placa),
                    FOREIGN KEY (conductor) REFERENCES Conductor(id)
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS Organizacion (
                    id TEXT PRIMARY KEY,
                    Director TEXT,
                    Integrantes TEXT,
                    Vehiculos TEXT,
                    Rutas TEXT,
                    FOREIGN KEY (Director) REFERENCES Admin(id),
                    FOREIGN KEY (Integrantes) REFERENCES Conductor(id),
                    FOREIGN KEY (Rutas) REFERENCES Ruta(id)
                )
            """)
            conn.commit()

            # Create the admin user.  This is done *after* the tables are created.
            cursor.execute("INSERT INTO users (id, contraseña) VALUES (?, ?)", ('admin', 'admin'))
            cursor.execute("INSERT INTO Admin (id) VALUES (?)", ('admin',))
            conn.commit()

        except sqlite3.Error as e:
            print(e)
        finally:
            conn.close()

create_tables() # Ensure all tables are created on startup, and the admin user is created.

# --- Define Pydantic models for data validation ---
class User(BaseModel):
    id: str
    name: str | None = None
    email: str | None = None
    telefono: str | None = None
    contraseña: str

class AdminModel(BaseModel):
    id: str

class ConductorModel(BaseModel):
    id: str

class VehiculoModel(BaseModel):
    placa: str
    kilometraje: float | None = None
    año: int | None = None
    modelo: str | None = None

class RutaModel(BaseModel):
    id: str
    autobus: str | None = None
    conductor: str | None = None
    paradas: str | None = None

class OrganizacionModel(BaseModel):
    id: str
    Director: str | None = None
    Integrantes: str | None = None
    Vehiculos: str | None = None
    Rutas: str | None = None

# --- Define API endpoints to interact with the database ---

@app.post("/users/", response_model=User, status_code=201)
def create_user(user: User):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO users (id, name, email, telefono, contraseña) VALUES (?, ?, ?, ?, ?)",
                       (user.id, user.name, user.email, user.telefono, user.contraseña))
        conn.commit()
        return user
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="User ID already exists")
    finally:
        conn.close()

@app.get("/users/{user_id}", response_model=User)
def read_user(user_id: str):
    conn = create_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, telefono, contraseña FROM users WHERE id=?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    if user:
        return User(id=user[0], name=user[1], email=user[2], telefono=user[3], contraseña=user[4])
    else:
        raise HTTPException(status_code=404, detail="User not found")

@app.post("/admins/", response_model=AdminModel, status_code=201)
def create_admin(admin: AdminModel):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO Admin (id) VALUES (?)", (admin.id,))
        conn.commit()
        return admin
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Admin ID already exists")
    finally:
        conn.close()

@app.post("/conductors/", response_model=ConductorModel, status_code=201)
def create_conductor(conductor: ConductorModel):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO Conductor (id) VALUES (?)", (conductor.id,))
        conn.commit()
        return conductor
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Conductor ID already exists")
    finally:
        conn.close()

@app.post("/vehiculos/", response_model=VehiculoModel, status_code=201)
def create_vehiculo(vehiculo: VehiculoModel):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO Vehiculo (placa, kilometraje, año, modelo) VALUES (?, ?, ?, ?)",
                       (vehiculo.placa, vehiculo.kilometraje, vehiculo.año, vehiculo.modelo))
        conn.commit()
        return vehiculo
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Vehicle plate already exists")
    finally:
        conn.close()

@app.post("/rutas/", response_model=RutaModel, status_code=201)
def create_ruta(ruta: RutaModel):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO Ruta (id, autobus, conductor, paradas) VALUES (?, ?, ?, ?)",
                       (ruta.id, ruta.autobus, ruta.conductor, ruta.paradas))
        conn.commit()
        return ruta
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Ruta ID already exists")
    except sqlite3.ForeignKeyError as e:
        raise HTTPException(status_code=400, detail=f"Foreign key constraint failed: {e}")
    finally:
        conn.close()

@app.post("/organizaciones/", response_model=OrganizacionModel, status_code=201)
def create_organizacion(organizacion: OrganizacionModel):
    conn = create_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("INSERT INTO Organizacion (id, Director, Integrantes, Vehiculos, Rutas) VALUES (?, ?, ?, ?, ?)",
                       (organizacion.id, organizacion.Director, organizacion.Integrantes, organizacion.Vehiculos, organizacion.Rutas))
        conn.commit()
        return organizacion
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Organization ID already exists")
    except sqlite3.ForeignKeyError as e:
        raise HTTPException(status_code=400, detail=f"Foreign key constraint failed: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info")
