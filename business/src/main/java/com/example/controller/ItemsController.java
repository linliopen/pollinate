package com.example.controller;

import com.example.entity.Items;
import com.example.service.ItemsService;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;


@RestController
@RequestMapping("/")
public class ItemsController {

    @Resource
    private ItemsService itemsService;

    @PostMapping("app")
    public String save(){
        Items items = new Items();
        itemsService.saveItem(items);
        return "ok";
    }


}