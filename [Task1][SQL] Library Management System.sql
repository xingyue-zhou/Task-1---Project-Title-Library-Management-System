-- create
CREATE TABLE Books (
  BOOK_ID INTEGER PRIMARY KEY,
  TITLE TEXT,
  AUTHOR TEXT,
  GENRE TEXT,
  YEAR_PUBLISHED INTEGER,
  AVAILABLE_COPIES INTEGER
);

CREATE TABLE Members (
  MEMBER_ID INTEGER PRIMARY KEY,
  NAME TEXT,
  EMAIL TEXT,
  PHONE_NO TEXT,
  ADDRESS TEXT,
  MEMBERSHIP_DATE DATE
);


CREATE TABLE BorrowingRecords (
  BORROW_ID INTEGER PRIMARY KEY,
  MEMBER_ID INTEGER,
  BOOK_ID INTEGER,
  BORROW_DATE DATE,
  RETURN_DATE DATE,
  FOREIGN KEY (MEMBER_ID) REFERENCES Members(MEMBER_ID),
  FOREIGN KEY (BOOK_ID) REFERENCES Books(BOOK_ID)
);

-- insert
INSERT INTO Books (BOOK_ID, TITLE, AUTHOR, GENRE, YEAR_PUBLISHED, AVAILABLE_COPIES)
VALUES
(1, 'first book', 'fisrt author', 'Fiction', 2001, 1),
(2, 'second book', 'second author', 'Poetry', 2002, 2),
(3, 'third book', 'third author', 'Classic', 2003, 3),
(4, 'fouth book', 'fisrt author', 'Fantasy', 2004, 4),
(5, 'fifth book', 'fifth author', 'Non-fiction', 2005, 5),
(6, 'sixth book', 'fisrt author', 'Fiction', 2006, 6);

INSERT INTO Members (MEMBER_ID, NAME, EMAIL, PHONE_NO, ADDRESS, MEMBERSHIP_DATE)
VALUES
(101, 'Jane Doe', 'jane@example.com', '123', '123 St', '2024-07-15'),
(102, 'Emma Smith', 'emma@example.com', '456', '456 St', '2024-11-20'),
(103, 'John Doe', 'john@example.com', '789', '789 St', '2025-01-01'),
(104, 'Lin', 'lin@example.com', '101', '101 St', '2024-12-01'),
(105, 'Anne', 'anne@example.com', '112', '112 St', '2024-12-01');

INSERT INTO BorrowingRecords (BORROW_ID, MEMBER_ID, BOOK_ID, BORROW_DATE, RETURN_DATE)
VALUES
(1001, 101, 1, '2025-03-01', '2025-03-15'),
(1002, 101, 3, '2025-05-01', '2025-05-15'),
(1003, 102, 4, '2025-05-28', '2025-06-05'),
(1004, 101, 2, '2025-06-01', '2025-04-15'),
(1005, 103, 1, '2025-06-10', '2025-07-20'),
(1006, 101, 4, '2025-06-20', NULL),
(1007, 102, 2, '2025-06-22', NULL),
(1008, 103, 4, '2025-06-25', NULL),
(1009, 101, 6, '2025-06-28', '2025-07-05'),
(1010, 102, 6, '2025-06-28', '2025-07-10'),
(1011, 105, 1, '2025-07-01', '2025-07-15'),
(1012, 103, 6, '2025-07-10', NULL),
(1013, 105, 4, '2025-07-20', '2025-07-30');

-- Information Retrieval:
-- a) Retrieve a list of books currently borrowed by a specific member.
SELECT
  m.NAME
  ,m.EMAIL
  ,b.*
FROM Books b
  INNER JOIN BorrowingRecords br
  ON b.BOOK_ID = br.BOOK_ID
  INNER JOIN Members m
  ON m.MEMBER_ID = br.MEMBER_ID
;

-- b) Find members who have overdue books (borrowed more than 30 days ago, not returned)
SELECT
  m.*
FROM Books b
  INNER JOIN BorrowingRecords br
  ON b.BOOK_ID = br.BOOK_ID
  INNER JOIN Members m
  ON m.MEMBER_ID = br.MEMBER_ID
WHERE RETURN_DATE IS NULL
AND DATEDIFF(current_date,BORROW_DATE) > 30
;

-- c) Retrieve books by genre along with the count of available copies.
WITH non_return_book as (
  SELECT
    BOOK_ID
    , count(br.BOOK_ID) as non_return_cnt
  FROM BorrowingRecords br
  WHERE RETURN_DATE IS NULL
  GROUP BY BOOK_ID
)

SELECT
  b.BOOK_ID
  , b.TITLE
  , b.AUTHOR
  , b.GENRE
  , b.YEAR_PUBLISHED
  , b.AVAILABLE_COPIES - COALESCE(nrb.non_return_cnt,0) as AVAILABLE_COPIES
FROM Books b
  LEFT JOIN non_return_book nrb
  ON b.BOOK_ID = nrb.BOOK_ID
;

-- d) Find the most borrowed book(s) overall.
WITH most_popular_book as (
  SELECT
    BOOK_ID
    , RANK() OVER (ORDER BY COUNT(BOOK_ID) DESC) AS borrow_rank
  FROM BorrowingRecords br
  GROUP BY BOOK_ID
)

SELECT
*
FROM Books
WHERE BOOK_ID = (SELECT BOOK_ID FROM most_popular_book WHERE borrow_rank = 1)
;

-- e) Retrieve members who have borrowed books from at least three different genres
WITH borrow_record AS (
  SELECT
    br.MEMBER_ID
    ,count(b.GENRE) as gener_cnt
  FROM Books b
    INNER JOIN BorrowingRecords br
    ON b.BOOK_ID = br.BOOK_ID
  GROUP BY br.MEMBER_ID
)

SELECT
*
FROM Members
WHERE MEMBER_ID IN (SELECT distinct MEMBER_ID FROM borrow_record WHERE gener_cnt >=3)
;

-- Reporting and Analytics:
-- a) Calculate the total number of books borrowed per month.
SELECT
  extract(month FROM br.BORROW_DATE) AS borrowed_month
  , count(br.BORROW_ID) AS borrow_number

FROM BorrowingRecords br
GROUP BY 1
ORDER BY 1
;

-- b) Find the top three most active members based on the number of books borrowed.
WITH borrowed_record AS (
  SELECT
    MEMBER_ID
    , RANK() OVER(ORDER BY COUNT(BOOK_ID) DESC) AS borrowed_rank
  FROM BorrowingRecords br
  GROUP BY MEMBER_ID
)

SELECT
  *
FROM Members
WHERE MEMBER_ID IN (SELECT distinct MEMBER_ID FROM borrowed_record WHERE borrowed_rank <=3)
;

-- c) Retrieve authors whose books have been borrowed at least 10 times.
WITH borrowed_record AS (
  SELECT
    BOOK_ID
    , COUNT(BOOK_ID) AS borrowed_cnt
  FROM BorrowingRecords br
  GROUP BY BOOK_ID
)

, author_cnt AS (
  SELECT
    b.AUTHOR
    , sum(borrowed_cnt) AS borrowed_total
  FROM Books b
    LEFT JOIN borrowed_record br
    ON b.BOOK_ID = br.BOOK_ID
  GROUP BY AUTHOR
)

SELECT *
FROM Books
WHERE AUTHOR IN (SELECT AUTHOR from author_cnt WHERE borrowed_total >= 10)
;

-- d) Identify members who have never borrowed a book
SELECT
  m.*
FROM Members m
    LEFT JOIN BorrowingRecords br
  ON m.MEMBER_ID = br.MEMBER_ID
WHERE br.MEMBER_ID IS NULL
;
