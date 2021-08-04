package com.example.dao;

import com.example.entity.Items;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;


@Mapper
public interface ItemsDao {


    Integer save(Items item);


}