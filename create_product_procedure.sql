CREATE PROCEDURE Create_Product
(
	@ProductCode varchar(100),
	@Price money,
	@Tax decimal(3,1),
	@Stock int,
	@ProductName varchar(100)
)
AS
BEGIN
	
	INSERT INTO Product(ProductCode, Price, Tax, Stock, ProductName)
	VALUES(@ProductCode, @Price, @Tax, @Stock, @ProductName)

END
GO


CREATE PROCEDURE Select_Customer
(
	@UserId uniqueidentifier NULL,
	@Email varchar(319) NULL

)
AS
BEGIN
	
	SELECT * FROM Customer
	WHERE( UserId IS NULL OR UserId = @UserId)
	AND (Email IS NULL OR Email = @Email)
	
END
GO

CREATE PROCEDURE Select_Total_Invoice
(
	@UserId UNIQUEIDENTIFIER NULL
)
AS
BEGIN
	SELECT Customer.UserId, Customer.Email, 
	SUM((DetailedOrder.Quantity * DetailedOrder.Price)) + 
	SUM(((DetailedOrder.Price * DetailedOrder.Quantity) * DetailedOrder.Tax) / 100) AS Total FROM Customer
	INNER JOIN CustomerOrder ON CustomerOrder.FK_CustomerId = Customer.UserId
	INNER JOIN DetailedOrder ON DetailedOrder.FK_OrderId = CustomerOrder.OrderId
	INNER JOIN Invoice ON Invoice.FK_OrderId = CustomerOrder.OrderId
	WHERE (@UserId IS NUll OR Customer.UserId = @UserId)
	GROUP BY Customer.UserId, Customer.Email
	ORDER BY Total DESC
END
GO

CREATE PROCEDURE Select_product
(
	@ProductId UNIQUEIDENTIFIER NULL
)
AS
BEGIN
	SELECT	* FROM Product WHERE ProductId NOT IN(
		SELECT DISTINCT(ProductId) FROM Product
		INNER JOIN DetailedOrder ON DetailedOrder.FK_ProductId = ProductId
		INNER JOIN CustomerOrder ON CustomerOrder.OrderId = DetailedOrder.FK_OrderId
		INNER JOIN Invoice ON Invoice.FK_OrderId = CustomerOrder.OrderId
		WHERE Invoice.CancellationDate IS NULL
	)
	ORDER BY ProductId
END
GO