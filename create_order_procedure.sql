CREATE PROCEDURE Create_Order
(
	@UserId uniqueidentifier,
	@OrderId uniqueidentifier,
	@ProductId uniqueidentifier,
	@OrderDate smalldatetime,
	@CancellationDate smalldatetime NULL,
	@Quantity int,
	@Price money,
	@Tax money
)
AS
BEGIN

	DECLARE @TaxAux decimal(3,1)
	DECLARE @PriceAux money
	DECLARE @StockAux int

	DECLARE @OrderTable TABLE(
		OrderId uniqueidentifier,
		OrderDate smalldatetime
	)

	--VALIDATE CUSTOMER
	IF(SELECT COUNT(*) FROM Customer WHERE UserId = @UserId) = 0
		BEGIN
			RAISERROR('Customer not found', 15, 1)
		END
	--VALIDATE PRODUCT
	IF(SELECT COUNT(*) FROM Product WHERE ProductId = @ProductId) = 0
		BEGIN
			RAISERROR('Product not found', 15, 1)
		END

	--GET PRODUCT PRICE, TAX AND STOCK
	SELECT @PriceAux=Price, @TaxAux=Tax, @StockAux=Stock FROM Product
	WHERE ProductId=@ProductId

	IF(@StockAux<@Quantity)
		BEGIN
			RAISERROR('Out of stock', 15, 1)
		END

	BEGIN TRANSACTION
	BEGIN TRY
		--VALIDATE ORDERID
		IF(@OrderId IS NULL)
			BEGIN
				INSERT INTO CustomerOrder(OrderDate, FK_CustomerId)
				OUTPUT INSERTED.OrderId, INSERTED.OrderDate INTO @OrderTable
				VALUES(GETDATE(), @UserId)
				SET @OrderId = (SELECT OrderId FROM @OrderTable)
			END
		ELSE --VALIDATE INVOICE
			BEGIN
				IF(SELECT COUNT(*) FROM Invoice WHERE FK_OrderId = @OrderId AND InvoiceDate IS NULL) > 0
					RAISERROR('Order is alreadey invoiced', 15, 1)
			END

		INSERT INTO DetailedOrder(Quantity, Price, Tax, FK_ProductId, FK_OrderId)
		VALUES(@Quantity, @PriceAux, @TaxAux, @ProductId, @OrderId)

		UPDATE Product SET Stock=@StockAux - @Quantity WHERE ProductId = @ProductId;
		
		IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_MESSAGE() AS ErrorMessage;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
	END CATCH
END
GO
