//
//  BookDAO.h
//  FMDBFrameWork
//
//  Created by king.wu on 7/21/16.
//  Copyright © 2016 king.wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BookData.h"

static const NSString *const BOOK_TABLE_NAME = @"bookTable";

static const NSString *const BOOK_ID_COLUMN = @"bookId";
static const NSString *const BOOK_NAME_COLUMN = @"bookName";
static const NSString *const BOOK_PAGECOUNT_COLUMN = @"bookPageCount";
static const NSString *const BOOK_DESCRIPTION_COLUMN = @"bookDescription"; //db version 3 add



/**
 *  用于对booktable CURD操作
 */
@class FMDBOpenHelper;
@interface BookDAO : NSObject

- (instancetype)initWithOpenHelper:(FMDBOpenHelper *)helper;


- (void)insertBookData:(BookData *)bookData;

- (void)insertBookDataArr:(NSArray<BookData *> *)bookDataArr;

- (BookData *)selectBookDataById:(NSString *)bookId;
@end
