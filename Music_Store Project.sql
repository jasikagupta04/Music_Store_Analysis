-- Q1: Who is the senior most employee based on job title?

SELECT * FROM employee;  

SELECT employee_id, last_name, first_name, title, levels FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?

SELECT * FROM invoice;

SELECT COUNT(*) as total_bills, ROUND(SUM(total):: NUMERIC,2), billing_country FROM invoice
GROUP BY billing_country
ORDER BY total_bills DESC
LIMIT 5;

-- Q3: What are top 3 values of total invoice?

SELECT * FROM invoice
ORDER BY total
LIMIT 3;

-- Q4: Which city has the best customers? 
-- We would like to throw a promotional Music Festival in the city we made the most money.
-- Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name & sum of all invoice totals.

SELECT * FROM invoice;

SELECT billing_city, ROUND(SUM(total):: NUMERIC,2) AS total_bills FROM invoice
GROUP BY billing_city
ORDER BY total_bills
LIMIT 10;

-- Q5: Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money.

SELECT * FROM customer;

SELECT customer.customer_id, customer.first_name, customer.last_name, ROUND(SUM(invoice.total):: NUMERIC,2) AS total_bill
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY total_bill DESC
LIMIT 5;

-- Q6:Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A.

SELECT * FROM invoice_line; 
SELECT * FROM invoice; 
SELECT * FROM genre; 
SELECT * FROM customer; 
SELECT * FROM track; 

SELECT DISTINCT customer.email, customer.first_name, customer.last_name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
WHERE track_id IN(SELECT track_id from track
					JOIN genre ON genre.genre_id = track.genre_id
					WHERE genre.name LIKE 'Rock')
ORDER BY customer.email ASC;

-- Other Way

SELECT DISTINCT customer.email, customer.first_name, customer.last_name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY customer.email ASC;

-- Q7: Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands. 

SELECT * FROM artist;
SELECT * FROM track;
SELECT * FROM  playlist;
SELECT * FROM album;

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS total_songs
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON track.album_id = album.album_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY total_songs DESC
LIMIT 10;

-- Q8: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first.

SELECT * FROM track;

SELECT name, milliseconds FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.

SELECT * FROM customer;
SELECT * FROM playlist;

WITH popular_artist AS (
	SELECT artist.artist_id as artist_id, artist.name as name, SUM(invoice_line.unit_price * invoice_line.quantity) AS total_spending 
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY artist.artist_id
	ORDER BY total_spending DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, pa.name, SUM(il.unit_price*il.quantity) AS total_amt
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN popular_artist pa ON pa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q8: We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres.

WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country AS country, genre.genre_id as genre_id, genre.name AS genre,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY customer.country, genre.genre_id, genre.name
	ORDER BY country ASC, purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <=1 
;

-- Q10: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 

WITH RECURSIVE customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_amt
	FROM invoice 
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 2,3 DESC),

max_spending AS (
	SELECT billing_country, MAX(total_amt) as max_spending
	FROM customer_with_country
	GROUP BY billing_country
)

SELECT * FROM customer_with_country cc
JOIN max_spending ms ON cc.billing_country = ms.billing_country
WHERE cc.total_amt = ms.max_spending
ORDER BY 1;