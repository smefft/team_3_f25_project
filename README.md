<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 53 00" src="https://github.com/user-attachments/assets/2b874e79-32d0-433c-bcea-e1ed230a4919" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 52 41" src="https://github.com/user-attachments/assets/156d7a4d-94cd-41da-bb46-6199bb4567bf" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 52 11" src="https://github.com/user-attachments/assets/25b707ca-0bef-4ce3-8fe1-661f86c8a773" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 40 09" src="https://github.com/user-attachments/assets/1e2cbfd1-0f2a-47cd-902b-3035421193c8" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 33 57" src="https://github.com/user-attachments/assets/113f3ced-f7f2-4e58-bf78-ee26b31adc17" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 33 28" src="https://github.com/user-attachments/assets/e58e1765-dc1e-4e2a-9010-cae0c943508f" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 33 19" src="https://github.com/user-attachments/assets/6d08d4a1-98e6-48c0-91b2-dcdaa76f1398" />
<img width="250" height="540" alt="Simulator Screenshot - iPhone 15 Pro - 2025-12-09 at 10 33 03" src="https://github.com/user-attachments/assets/7452263e-90e7-4532-ac88-a74a9201bf8f" />


# Milestone 0

## Folder Layout
- **Screens**  
  The different types of widget trees/screens the users (teacher or student) will see.
- **Models**  
  The various classes/objects that define our app’s data.
- **Widget**  
  Reusable widget files and data structures.
- **Data**  
  The wordlist data used for students.

---

## Screens

### Login Screen
The first screen users will see.  
Users enter a username and password.  
Each user has a **role** (Student or Teacher) which determines their navigation path.

### Wordlist Selector (Student)
Students choose which word list to practice.  
**Options:** Phonic or Custom lists.

### Practice Screen (Student)
Shows **one word card at a time** with a button to record pronunciation.

### Feedback Screen (Student)
Appears after practice to show:
- Success or Needs Work indicator
- Guidance/tips
- Score of the attempt

### Progress Screen (Student)
Displays **simple progress charts** over time for each word list.

### Dashboard (Teacher)
Shows:
- Averages
- Attempts
- Struggling words
- Students list

Extra teacher features:
- Upload CSV of custom lists
- Toggle audio retention per student
- Filter by **student**, **wordlist**, and **time window**

---

## Models

### User
| Field | Type | Notes |
|-------|------|------|
| UID | int | Identifier |
| Email | String | User login / contact |
| Name | String | Full name |
| Role | String | Student or Teacher |

### Wordlist
| Field | Type | Notes |
|-------|------|------|
| ID | int | Word list identifier |
| Word | String | Practice word |
| Category | String | Phonic or Custom |
| Sentence | String | Example usage |

### Settings
| Field | Type | Notes |
|-------|------|------|
| UID | int | Links to user |
| Retain Audio | bool | Toggle for storing recording attempts |
| Retention Time | int | Duration of audio storage |

### Attempts
Tracks each pronunciation effort:

| Field | Type | Notes |
|-------|------|------|
| ID | int | ID of Attempt
| UID | int | ID of Student
| Student Name | String | Name of Student
| Wordlist ID| Int | ID of wordlist word is in
| Word | String | Word Text
| Score | int | Score of attempt
| Feedback | String | Feedback base on audio
| Audio | String | Audio Reference
| CreatedOn | Date object | Time Attempt was created

---

## Widgets
- **Word Card**: Displays a word and example sentence
- **Record Button**: Records student audio
- **Feedback Card**: Shows score and feedback message
- **Progress Chart**: Visual representation of word list progress

---

## Data
- **Seed_words.csv**: Default set of words (phonic or custom)

---

## Navigation Flow
Student:

Login -> Wordlist Selector -> Practice -> Feedback -> Progress -> Wordlist Selector or Practice

Teacher:

Login -> Dashboard
