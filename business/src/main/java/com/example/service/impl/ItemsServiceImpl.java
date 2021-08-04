package com.example.service.impl;

import com.example.entity.Items;
import com.example.dao.ItemsDao;
import com.example.service.ItemsService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;


@Service("itemsService")
public class ItemsServiceImpl implements ItemsService {
    @Resource
    private ItemsDao itemsDao;


    @Override
    public Integer saveItem(Items items) {
        return itemsDao.save(items);
    }
}