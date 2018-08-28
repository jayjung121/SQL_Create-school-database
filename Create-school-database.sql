--**********************************************************************************************--
-- Title: Info340Midterm
-- Author: ByungSuJung
-- Desc: This file demonstrates how to design and create; 
--       tables, views, and stored procedures
-- Change Log: When,Who,What
-- 2017-07-11,ByungSuJung,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Info340MidtermDB_ByungSuJung')
	 Begin 
	  Alter Database [Info340MidtermDB_ByungSuJung] set Single_user With Rollback Immediate;
	  Drop Database Info340MidtermDB_ByungSuJung;
	 End
	Create Database Info340MidtermDB_ByungSuJung;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Info340MidtermDB_ByungSuJung;
go

-- Create Tables (Module 01)-- 
Create
Table Courses(
	CourseID int Identity (1,1) Not Null,
	CourseName nvarchar(100) Not Null Unique,
	CourseStartDateTime datetime Null,
	CourseEndDateTime datetime Null,
	CourseCurrentPrice money Null 

	Constraint pkCourses Primary Key Clustered(
		CourseID
	)
);
Go

Create
Table Students(
	StudentID int Identity (1, 1) Not Null,
	StudentNumber nVarchar(100) Unique Not Null ,
	StudentFirstName nVarchar(100) Not Null,
	StudentLastName	nVarchar(100) Not Null,
	StudentEmail nVarchar(100) Unique Not Null,
	StudentPhone nVarchar(100) Null,
	StudentAddress1	nVarchar(100) Not Null,
	StudentAddress2	nVarchar(100) Null,
	StudentCity	nVarchar(100) Not Null,
	StudentStateCode nChar(2) Not Null,
	StudentZipCode nVarChar(10) Not Null

	Constraint pkStudents Primary Key Clustered(
		StudentID
	)
);
Go

Create
Table Enrollments(
	EnrollmentID int Identity (1,1) Not Null,
	StudentID int Not Null,
	CourseID int Not Null,
	EnrollmentDateTime datetime Not Null,
	EnrollmentPrice money Not Null

	Constraint pkEnrollments Primary Key Clustered(
		EnrollmentID
	)
);
Go

-- Courses Constraints --
Begin

Alter Table Courses
	Add Constraint ckEndDateIsGreaterThanStartDate Check (
		CourseEndDateTime > CourseStartDateTime
	);

End
Go

-- Students Constraints --
Begin

Alter Table Students
	Add Constraint ckStudentPhonePattern Check (
		StudentPhone like '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	);

Alter Table Students
	Add Constraint ckStudentZipCode Check (
		StudentZipCode like ('[0-9][0-9][0-9][0-9][0-9]')
		or StudentZipCode like ('[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
	);

End
Go

-- Enrollments Constraints --
Begin

Alter Table Enrollments
	Add Constraint fkEnrollments_Students Foreign Key(
		StudentID
	) References Students(
		StudentID
	);

Alter Table Enrollments
	Add Constraint fkEnrollments_Courses Foreign Key(
		CourseID
	) References Courses(
		CourseID
	);

Alter Table Enrollments
	Add Constraint dfEnrollmentDateTime Default 
		getdate() for EnrollmentDateTime;

End
Go

-- Create a function -- 
Create Function dbo.fGetCourseEndDate (@CourseID int)
 Returns datetime
As
Begin
 Return (Select CourseEndDateTime 
         From Courses
		 Where Courses.CourseID = @CourseID);
End
Go

-- Additional Constraints with Function --
Alter Table Enrollments
	Add Constraint ckEnrollmentDateTimeBeforeCourseEndDate Check (
		EnrollmentDateTime < dbo.fGetCourseEndDate(Enrollments.CourseID)
	);
Go

-- Adding Views (Module 03 and 04) -- 

Create View vCourses
As
Select [CourseID],
	   [CourseName], 
	   [CourseStartDateTime], 
	   [CourseEndDateTime], 
	   [CourseCurrentPrice] = Format(CourseCurrentPrice, 'C', 'en-us')
From Courses;
Go

Create View vStudents
As
Select [StudentID], 
	   [StudentNumber], 
	   [StudentFirstName], 
	   [StudentLastName], 
	   [StudentEmail], 
	   [StudentPhone], 
	   [StudentAddress1], 
	   [StudentAddress2], 
	   [StudentCity], 
	   [StudentStateCode], 
	   [StudentZipCode]
From Students;
Go

Create View vEnrollments
As
Select [EnrollmentID],
	   [StudentID], 
	   [CourseID], 
	   [EnrollmentDateTime], 
	   [EnrollmentPrice] = Format(EnrollmentPrice, 'C', 'en-us')
From Enrollments;
Go

Create View vCoursesStudentsEnrollments
As
Select c.[CourseID],
	   c.[CourseName], 
	   c.[CourseStartDateTime], 
	   c.[CourseEndDateTime], 
	   [CourseCurrentPrice] = Format(c.CourseCurrentPrice, 'C', 'en-us'),
	   s.[StudentID], 
	   s.[StudentNumber], 
	   s.[StudentFirstName], 
	   s.[StudentLastName], 
	   s.[StudentEmail], 
	   s.[StudentPhone], 
	   s.[StudentAddress1], 
	   s.[StudentAddress2], 
	   s.[StudentCity], 
	   s.[StudentStateCode], 
	   s.[StudentZipCode],
	   e.[EnrollmentID],
	   e.[EnrollmentDateTime], 
	   [EnrollmentPrice] = Format(e.EnrollmentPrice, 'C', 'en-us')
From Enrollments as e
Join Courses as c
 On e.CourseID = c.CourseID
Join Students as s
 On e.StudentID = s.StudentID
Go

-- Adding Stored Procedures (Module 04 and 05) --

-- Inserts --

Create Procedure pInsCourses
(@CourseName nvarchar(100),
 @CourseStartDateTime datetime,
 @CourseEndDateTime datetime,
 @CourseCurrentPrice money
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which inserts data into courses table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into Courses
	([CourseName], [CourseStartDateTime], [CourseEndDateTime], [CourseCurrentPrice])
	Values
	(@CourseName, @CourseStartDateTime, @CourseEndDateTime, @CourseCurrentPrice)
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pInsStudents
(@StudentNumber nVarchar(100) ,
 @StudentFirstName nVarchar(100),
 @StudentLastName	nVarchar(100),
 @StudentEmail nVarchar(100),
 @StudentPhone nVarchar(100),
 @StudentAddress1	nVarchar(100),
 @StudentAddress2	nVarchar(100),
 @StudentCity	nVarchar(100),
 @StudentStateCode nChar(2),
 @StudentZipCode nVarChar(10)
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which inserts data into Students table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into Students
	([StudentNumber], [StudentFirstName], [StudentLastName], [StudentEmail], [StudentPhone], 
	 [StudentAddress1], [StudentAddress2], [StudentCity], [StudentStateCode], [StudentZipCode])
	Values
	(@StudentNumber, @StudentFirstName, @StudentLastName, @StudentEmail, @StudentPhone, 
	 @StudentAddress1, @StudentAddress2, @StudentCity, @StudentStateCode, @StudentZipCode)
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pInsEnrollments
(@StudentID int,
 @CourseID int,
 @EnrollmentDateTime datetime,
 @EnrollmentPrice money
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which inserts data into Enrollments table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into Enrollments
	([StudentID], [CourseID], [EnrollmentDateTime], [EnrollmentPrice])
	Values
	(@StudentID, @CourseID, @EnrollmentDateTime, @EnrollmentPrice)
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pUpdCourses
(@CourseID int,
 @CourseName nvarchar(100),
 @CourseStartDateTime datetime,
 @CourseEndDateTime datetime,
 @CourseCurrentPrice money
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which update data into Courses table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Update Courses
	 Set
	  [CourseName] = @CourseName, 
	  [CourseStartDateTime] = @CourseStartDateTime, 
	  [CourseEndDateTime] = @CourseEndDateTime, 
	  [CourseCurrentPrice] =  @CourseCurrentPrice
	  Where [CourseID] = @CourseID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pUpdStudents
(@StudentID int,
 @StudentNumber nVarchar(100) ,
 @StudentFirstName nVarchar(100),
 @StudentLastName	nVarchar(100),
 @StudentEmail nVarchar(100),
 @StudentPhone nVarchar(100),
 @StudentAddress1	nVarchar(100),
 @StudentAddress2	nVarchar(100),
 @StudentCity	nVarchar(100),
 @StudentStateCode nChar(2),
 @StudentZipCode nVarChar(10)
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which update data in Students table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Update Students
	 Set
	  [StudentNumber] = @StudentNumber,
	  [StudentFirstName] = @StudentFirstName,
	  [StudentLastName] = @StudentLastName, 
	  [StudentEmail] = @StudentEmail, 
	  [StudentPhone] = @StudentPhone, 
	  [StudentAddress1] = @StudentAddress1, 
	  [StudentAddress2] = @StudentAddress2, 
	  [StudentCity] = @StudentCity, 
	  [StudentStateCode] = @StudentStateCode, 
	  [StudentZipCode] = @StudentZipCode
	  Where [StudentID] = @StudentID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pUpdEnrollments
(@EnrollmentID int,
 @StudentID int,
 @CourseID int,
 @EnrollmentDateTime datetime,
 @EnrollmentPrice money
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which inserts data into Enrollments table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Update Enrollments
	 Set
	  [StudentID] = @StudentID,
	  [CourseID] = @CourseID,
	  [EnrollmentDateTime] = @EnrollmentDateTime, 
	  [EnrollmentPrice] = @EnrollmentPrice
	  Where [EnrollmentID] = @EnrollmentID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

-- Delete --

Create Procedure pDelCourses
(@CourseID int
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which delete data into Courses table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete From Courses
	 Where [CourseID] = @CourseID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go


Create Procedure pDelStudents
(@StudentID int
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which delete data in Students table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete From Students
	 Where [StudentID] = @StudentID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

Create Procedure pDelEnrollments
(@EnrollmentID int
)
/* Author: <ByungSuJung>
** Desc: Create transaction stored procedure which inserts data into Enrollments table.
** Change Log: When,Who,What
** <2018-07-11>,<ByungSuJung>,Created stored procedure.
*/
As
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete From Enrollments
	  Where [EnrollmentID] = @EnrollmentID
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Print Error_Number()
   Set @RC = -1
  End Catch
  Return @RC;
 End
Go

-- Test Stored Procedures -- 

------------------------------Insert----------------------------------

Declare @Status int, @NewCourseID int, @NewStudentID int, @NewEnrollmentID int;

Begin
-- Courses --
 Exec @Status = pInsCourses
	  @CourseName = 'CourseA',
	  @COurseStartDateTime = '2017-01-21',
	  @CourseEndDateTime = '2017-03-25',
	  @CourseCurrentPrice = 300;
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @NewCourseID = @@Identity;

-- Students --
 Exec @Status = pInsStudents
	  @StudentNumber = 'TestStudentNum', 
	  @StudentFirstName = 'Jay', 
	  @StudentLastName = 'Jung', 
	  @StudentEmail = 'jbsoo93@gmail.com', 
	  @StudentPhone = '206-954-3499', 
	  @StudentAddress1 = '4225 9th Ave', 
	  @StudentAddress2 = 'Apt#3', 
	  @StudentCity = 'Seattle', 
	  @StudentStateCode = 'WA', 
	  @StudentZipCode = '98105'
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @NewStudentID = @@Identity;

-- Enrollments --
 Exec @Status = pInsEnrollments
	  @StudentID = @NewStudentID, 
	  @CourseID = @NewCourseID, 
	  @EnrollmentDateTime = '2017-01-21', 
	  @EnrollmentPrice = $399
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]

End
Select * From vCoursesStudentsEnrollments;
------------------------- Update ----------------------

Begin 
-- Courses -- 
 Exec @Status = pUpdCourses
	  @CourseID = @NewCourseID,
	  @CourseName = 'CourseB',
	  @COurseStartDateTime = '2000-01-21',
	  @CourseEndDateTime = '2000-03-25',
	  @CourseCurrentPrice = 800;
 Select Case @Status
  When +1 Then 'Update was successful'
  When -1 then 'Update failed. Commom issues: Duplicate Data'
  End As [Status];

  -- Students --
 Exec @Status = pUpdStudents
	  @StudentID = @NewStudentID,
	  @StudentNumber = 'UpdatetudentNum', 
	  @StudentFirstName = 'Jayzzz', 
	  @StudentLastName = 'Jungggg', 
	  @StudentEmail = 'abced@gmail.com', 
	  @StudentPhone = '999-999-3499', 
	  @StudentAddress1 = '1669 5th Ave', 
	  @StudentAddress2 = 'Apt#6', 
	  @StudentCity = 'zSeattle', 
	  @StudentStateCode = 'zA', 
	  @StudentZipCode = '99105'
 Select Case @Status
  When +1 Then 'Update was successful'
  When -1 then 'Update failed. Commom issues: Duplicate Data'
  End As [Status];

-- Enrollments --
 Exec @Status = pUpdEnrollments
	  @EnrollmentID = @NewEnrollmentID,
	  @StudentID = @NewStudentID, 
	  @CourseID = @NewCourseID, 
	  @EnrollmentDateTime = '2000-01-21', 
	  @EnrollmentPrice = $399
 Select Case @Status
  When +1 Then 'Update was successful'
  When -1 then 'Update failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @NewEnrollmentID = @@Identity;

End
Select * From vCoursesStudentsEnrollments;
 ---------------------- Delete -------------------------
Begin
-- Enrollments --
 Exec @Status = pDelEnrollments
	  @EnrollmentID = @NewEnrollmentID
 Select Case @Status
  When +1 Then 'Delete was successful'
  When -1 then 'Delete failed. Commom issues: Foreign Key Violation'
  End As [Status];

 -- Courses -- 
 Exec @Status = pDelCourses
	  @CourseID = @NewCourseID
 Select Case @Status
  When +1 Then 'Delete was successful'
  When -1 then 'Delete failed. Commom issues: Foreign Key Violation'
  End As [Status];

-- Students --
 Exec @Status = pDelStudents
	  @StudentID = @NewStudentID
 Select Case @Status
  When +1 Then 'Delete was successful'
  When -1 then 'Delete failed. Commom issues: Foreign Key Violation'
  End As [Status];

End
Go
Select * From vCoursesStudentsEnrollments;


------------------------------- Insert Data ----------------------------
-- Courses --
Declare @Status int, @Course1ID int, @Course2ID int, @BobStudentID int, @SueStudentID int;
Begin

 Exec @Status = pInsCourses
	  @CourseName = 'SQL1 - Winter 2017',
	  @COurseStartDateTime = '2017-01-10 6:00 PM',
	  @CourseEndDateTime = '2017-01-24 8:50PM',
	  @CourseCurrentPrice = $399;
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @Course1ID = @@IDENTITY;

 Exec @Status = pInsCourses
	  @CourseName = 'SQL2 - Winter 2017',
	  @COurseStartDateTime = '2017-01-31 6:00 PM',
	  @CourseEndDateTime = '2017-02-14 8:50PM',
	  @CourseCurrentPrice = $399;
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @Course2ID = @@IDENTITY;
-- Students --

 Exec @Status = pInsStudents
	  @StudentNumber = 'B-Smith-071', 
	  @StudentFirstName = 'Bod', 
	  @StudentLastName = 'Smith', 
	  @StudentEmail = 'Bsmith@HipMail.com', 
	  @StudentPhone = '206-111-2222', 
	  @StudentAddress1 = '123 Main St', 
	  @StudentAddress2 = Null, 
	  @StudentCity = 'Seattle', 
	  @StudentStateCode = 'WA', 
	  @StudentZipCode = '98001'
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @BobStudentID = @@IDENTITY;

 Exec @Status = pInsStudents
	  @StudentNumber = 'S-Jones-003', 
	  @StudentFirstName = 'Sue', 
	  @StudentLastName = 'Jones', 
	  @StudentEmail = 'SueJones@YaYou.com', 
	  @StudentPhone = '206-231-4321', 
	  @StudentAddress1 = '333 1st Ave', 
	  @StudentAddress2 = Null, 
	  @StudentCity = 'Seattle', 
	  @StudentStateCode = 'WA', 
	  @StudentZipCode = '98001'
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status]
 Set @SueStudentID = @@IDENTITY

  -- Enrollments --
 Exec @Status = pInsEnrollments
	  @StudentID = @BobStudentID, 
	  @CourseID = @Course1ID, 
	  @EnrollmentDateTime = '2017-01-03', 
	  @EnrollmentPrice = $399
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status];

 Exec @Status = pInsEnrollments
	  @StudentID = @BobStudentID, 
	  @CourseID = @Course2ID, 
	  @EnrollmentDateTime = '2017-01-12', 
	  @EnrollmentPrice = $399
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status];

 Exec @Status = pInsEnrollments
	  @StudentID = @SueStudentID, 
	  @CourseID = @Course1ID, 
	  @EnrollmentDateTime = '2016-12-14', 
	  @EnrollmentPrice = $349
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status];

 Exec @Status = pInsEnrollments
	  @StudentID = @SueStudentID, 
	  @CourseID = @Course2ID, 
	  @EnrollmentDateTime = '2016-12-14', 
	  @EnrollmentPrice = $349
 Select Case @Status
  When +1 Then 'Insert was successful'
  When -1 then 'Insert failed. Commom issues: Duplicate Data'
  End As [Status];

End
Go

-------------------------- Final check on Insertion using Views---------------------------
Select * From vCourses
Select * From vStudents
Select * From vEnrollments
Go

-- Set Permission -- 
Begin
-- Courses -- 
Deny Select, Insert, Update, Delete On Courses To Public;
Grant Select On vCourses To Public;
Grant Exec On pInsCourses To Public;
Grant Exec On pUpdCourses To Public;
Grant Exec On pDelCourses To Public;
-- Students -- 
Deny Select, Insert, Update, Delete On Students To Public;
Grant Select On vStudents To Public;
Grant Exec On pInsStudents To Public;
Grant Exec On pUpdStudents To Public;
Grant Exec On pDelStudents To Public;
-- Enrollment -- 
Deny Select, Insert, Update, Delete On Enrollments To Public;
Grant Select On vEnrollments To Public;
Grant Exec On pInsEnrollments To Public;
Grant Exec On pUpdEnrollments To Public;
Grant Exec On pDelEnrollments To Public;
End

